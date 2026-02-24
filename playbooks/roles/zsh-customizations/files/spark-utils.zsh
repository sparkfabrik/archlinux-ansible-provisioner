# Helper function to check if a command exists
command_exists() {
  command -v "${1}" &> /dev/null
}

# Google Cloud aliases
if command_exists gcloud; then
  alias gcloud-as='gcloud config set auth/impersonate_service_account'
  alias gcloud-me='gcloud config unset auth/impersonate_service_account'
  alias gcloud-whoami='gcloud config get auth/impersonate_service_account 2>/dev/null || echo "none"'
fi

# AI tool completions
if command_exists opencode; then
  source <(opencode completion)
fi

if command_exists openspec; then
  source <(openspec completion generate zsh)
fi
