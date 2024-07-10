
# Centralized data management platform sample

This repository allows you to quickly spin up a data management platform made with a number of open source applications in your own environment. It aims at giving you an idea of what a modernized data management looks like. Feel free to comment if you have any thought!


## Pre-requisite
1. Prepare a machine running in Ubuntu with Internet access. (Mine was Ubuntu 20.04 with 8vcpu / 32g memory in Azure Southeast Asia when I developed this platform). I recommend a new and clean machine to avoid any issue
2. Download this repository into your machine
3. Change the <Your VM IP> in demo/data-mgmt-portal-deploy/values.yaml to your machine public IP
4. (Optional) Prepare your own OpenAI key if you want to try the Chatbot feature
5. Run the setup.sh as below to install Docker, Kubernetes, Helm and all required applications on K8s in the machine (this takes 30 - 40 mins)
```bash
export OPENAI_KEY=<Your OpenAI API key>  ## can skip this step if you don't need to use GenAI chatbot
chmod +x all-in-one/setup.sh
./all-in-one/setup.sh
```


## Links

| Application | URL    | Description |
| :-------- | :------- | :------- |
| Data management portal | http://<Your VM IP>:30030 | Centralized portal for necessary data activities, e.g. dataset deployment, GenAI chatbot |
| Denodo Sandbox | http://<Your VM IP>:30290/denodo-design-studio  | Core data platform for data users to perform testing |
| Denodo Production | http://<Your VM IP>:30190/denodo-design-studio  |Core data platform for production use |
| DataHub | http://<Your VM IP>:31002  | Data Catalog and data lineage |
| Zammad | http://<Your VM IP>:30880  | ITSM (not necessary for data platform but to provide end-to-end governed data workflow) |
| Jenkins | http://<Your VM IP>:30808  | CD pipeline for dataset deployment |