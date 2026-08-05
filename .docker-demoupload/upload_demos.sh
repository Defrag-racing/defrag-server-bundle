#!/bin/bash

# Only the native install has an sv.conf to read; in the container every one of
# these arrives as an environment variable from docker-compose. Sourcing it
# unconditionally printed "sv.conf: No such file or directory" on every single
# run, which reads like the upload failed when nothing is wrong.
[ -f sv.conf ] && source sv.conf

# Check if .env file exists and has required variables
if [[ -z "${DEMO_SFTP_ENABLED}" || "${DEMO_SFTP_ENABLED}" -eq 0 ]] ; then
    exit 1
fi

if [[ -z "${DEMO_SFTP_USER}" || -z "${DEMO_SFTP_PASS}" ]] ; then
    echo "Missing credentials for automatic demo uploading (DEMO_SFTP_USER / DEMO_SFTP_PASS), skipping..."
    exit 1
fi

# Check if .env file exists and has required variables
if [[ -z "$DEMO_SFTP_REMOTEDIR" ]]; then
    echo "Error: Missing DEMO_SFTP_REMOTEDIR."
    exit 1
fi

# Function to upload demos and preserve folder structure
base_path=${DEMO_SFTP_LOCAL_DIRECTORY:-./game/defrag/}
# Strip a trailing slash, otherwise the ${demo_file#$base_path/} below is
# looking for a doubled slash, never matches, and the whole local path ends
# up in the remote one (/demos/./game/defrag/serverdemos/... instead of
# /demos/serverdemos/...). The Dockerfile sets this without a trailing slash,
# so only dockerless installs running on the default were affected.
base_path=${base_path%/}

sftp_run() {
    sshpass -p "$DEMO_SFTP_PASS" sftp \
        -o StrictHostKeyChecking=no -P "${DEMO_SFTP_PORT}" \
        "$@" "${DEMO_SFTP_USER}@${DEMO_SFTP_HOST}"
}

uploaded=0
failed=0

# Find all demo files excluding tmp folders. Reading from a process
# substitution rather than a pipe keeps the loop in this shell, so the
# counters below survive it.
while IFS= read -r demo_file; do
    # Get relative path from base demo directory
    relative_path=${demo_file#$base_path/}
    remote_dir=$(dirname "${relative_path}")

    echo "Found demo file at filepath: $demo_file"
    echo "Uploading file to: ${DEMO_SFTP_REMOTEDIR}/${relative_path}"

    # Create the remote directory structure if needed. This pass runs without
    # -b and its exit status is ignored on purpose: the directories usually
    # already exist, and "mkdir: failure" on an existing directory is the
    # normal case, not an error worth acting on.
    if [[ "$remote_dir" != "." ]]; then
        mkdir_commands=$(mktemp)
        # Split path and create each directory level
        IFS='/' read -ra DIRS <<< "${remote_dir}"
        current_path="${DEMO_SFTP_REMOTEDIR}"
        for dir in "${DIRS[@]}"; do
            current_path="${current_path}/${dir}"
            echo "mkdir \"${current_path}\"" >> "${mkdir_commands}"
        done
        echo "quit" >> "${mkdir_commands}"
        sftp_run < "${mkdir_commands}" > /dev/null 2>&1
        rm -f "${mkdir_commands}"
    fi

    # Upload the file. This one MUST run under -b: sftp reading commands from
    # stdin carries on past a failed command and still exits 0, so a put that
    # died on a full disk used to look like success - and the local demo, the
    # only remaining copy, was deleted on the next line. Under -b sftp aborts
    # on the first error and the exit status finally means something.
    #
    # -b also implies BatchMode=yes for ssh, which would kill the password
    # auth this whole script relies on. ssh keeps the FIRST value it is given
    # for an option, so passing BatchMode=no ahead of -b restores it while
    # leaving sftp's own abort-on-error behavior intact.
    put_commands=$(mktemp)
    echo "put \"${demo_file}\" \"${DEMO_SFTP_REMOTEDIR}/${relative_path}\"" >> "${put_commands}"

    if sftp_run -oBatchMode=no -b "${put_commands}"; then
        echo "Successfully uploaded: $relative_path"
        # Delete the source file after successful upload
        rm "${demo_file}"
        echo "Deleted source file: ${demo_file}"
        uploaded=$((uploaded + 1))
    else
        # Keep the local file and move on to the next demo. Aborting the whole
        # run here would leave the rest of the queue untried, and a transient
        # failure on one demo says nothing about the others.
        echo "Failed to upload: ${relative_path} - keeping the local file"
        failed=$((failed + 1))
    fi

    # Clean up temp file
    rm -f "${put_commands}"
done < <(find "$base_path" \( -name "*.dm_68" -o -name "*.dm_*" \) ! -path "*/tmp/*")

echo "Demo upload process completed: ${uploaded} uploaded, ${failed} failed."

# Non-zero on failure so the cron log (and anyone watching it) can tell a
# clean run from one that left demos behind.
[[ "$failed" -eq 0 ]]
