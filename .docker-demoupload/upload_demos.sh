#!/bin/bash

source sv.conf

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

# Find all demo files excluding tmp folders
find "$base_path" -name "*.dm_68" -o -name "*.dm_*" | grep -v "/tmp/" | while read -r demo_file; do
    # Get relative path from base demo directory
    relative_path=${demo_file#$base_path/}
    remote_dir=$(dirname "${relative_path}")

    echo "Found demo file at filepath: $demo_file"
    echo "Uploading file to: ${DEMO_SFTP_REMOTEDIR}/${relative_path}"

    # Create SFTP batch commands
    sftp_commands=$(mktemp)

    # Create remote directory structure if needed
    if [[ "$remote_dir" != "." ]]; then
        # Split path and create each directory level
        IFS='/' read -ra DIRS <<< "${remote_dir}"
        current_path="${DEMO_SFTP_REMOTEDIR}"
        for dir in "${DIRS[@]}"; do
            current_path="${current_path}/${dir}"
            echo "mkdir \"${current_path}\"" >> "${sftp_commands}"
        done
    fi

    # Upload the file
    echo "put \"${demo_file}\" \"${DEMO_SFTP_REMOTEDIR}/${relative_path}\"" >> "${sftp_commands}"
    echo "quit" >> "${sftp_commands}"

    # Execute SFTP upload
    if sshpass -p "$DEMO_SFTP_PASS" sftp -o StrictHostKeyChecking=no -P "${DEMO_SFTP_PORT}" "${DEMO_SFTP_USER}@${DEMO_SFTP_HOST}" < "${sftp_commands}"; then
        echo "Successfully uploaded: $relative_path"
        # Delete the source file after successful upload
        rm "${demo_file}"
        echo "Deleted source file: ${demo_file}"
    else
        echo "Failed to upload: ${relative_path}"
        exit 1
    fi

    # Clean up temp file
    rm "${sftp_commands}"
done

echo "Demo upload process completed."