ping_calib:
	@ansible -i hosts_calibnet -m ping_calib

ping_main:
	@ansible -i hosts_mainnet -m ping_calib

forest_calib:
	@ansible-playbook -i hosts_calibnet forest-calib.yaml

forest_main:
	@ansible-playbook -i hosts_mainnet forest-mainnet.yaml

observ_calib:
	@ansible-playbook -i hosts_calibnet observability.yaml

observ_main:
	@ansible-playbook -i hosts_mainnet observability.yaml

lets_main:
	@ansible-playbook -i hosts_mainnet letsencrypt.yaml

lets_calib:
	@ansible-playbook -i hosts_calibnet letsencrypt.yaml
