# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Check if the docker group exists, and create it if it doesn't:
if ! getent group docker > /dev/null; then
    sudo groupadd docker || exit 1
fi

# Add the current user to the docker group:
sudo usermod -aG docker "$USER" || exit 1

# Notify user about logging out:
echo "Please log out and back in to apply group changes."

# Run hello-world in a subshell to verify installation:
(docker run hello-world) || { echo "Docker run failed."; exit 1; }
