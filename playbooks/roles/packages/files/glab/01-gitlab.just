[group('gitlab')]
gitlab-configure-glab:
    #!/usr/bin/env bash
    export GLAB_SEND_TELEMETRY=false

    if ! command -v glab &>/dev/null; then
      echo "❌ glab is not installed. Please install it first using the provisioner."
      exit 1
    fi

    glab auth login
