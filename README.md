
# Centralized data management platform sample

This repository allows you to quickly spin up a data management platform made with a number of open source applications in your own environment. It aims at giving you an idea of what a modernized data management looks like. Feel free to comment if you have any thought!


## Pre-requisite
1. Prepare a machine running in Ubuntu with Internet access. (Mine was Ubuntu 20.04 with 8vcpu / 32g memory in Azure when I developed this platform). I recommend a new and clean machine to avoid any issue
2. Copy the setup.sh file from this repository into your machine
3. Run the setup.sh as below to Docker, Kubernetes and Helm in the machine
```bash
export OPENAI_KEY=<Your OpenAI API key>  ## can skip this step if you don't need to use GenAI chatbot
## Go to the directory containing the setup.sh
chmod +x setup.sh
./setup.sh

```
4. Relogin the VM and open the proxy so you can access the K8s dashboard through browser
```bash
microk8s dashboard-proxy
```
5. Login to Jenkins using the below command to get the key
![App Screenshot](https://live.staticflickr.com/65535/53514564865_48716bfc9b_o_d.png)
```bash
sudo cat <path shown on the screen>
```
6. Choose "Install suggested plugins"; and then skip and continue as admin; click "Not now" for Instance Configuration


## Links
1. http://<Your VM IP>:30290/denodo-design-studio         Denodo Sandbox
2. http://<Your VM IP>:30880      Zammad
