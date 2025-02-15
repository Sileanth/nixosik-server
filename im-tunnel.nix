{pkgs, ...}: 

{
   users.users = {
     im-tunnel = {
       isNormalUser = true;
       openssh.authorizedKeys.keys = [
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDtAeduMbJF6KscsV8KkZ4a5k6jPzWckUzy1tvBb8uVZq7ZRHxssv/x3EzjcZSxXcILQfRJ3sK0lsd9sIWXc8LJeO9auctJ+U6bsgC6RM2qLffR8gRxUVVw06AUIs50lGtdqYEXv8WRHSnwiK+s4DJDtXqEceFWB+q0MhuPcfgF68mScqydOQZcaKVUZu3sMcPHwFzqgkdnRfpcpa5p5pXDTtkKgHeUuA34Jf9071Z9IGCjAmq0+YT8icEGb0F57+Nu4YJq4Nn2hRjKAjuZMJtirZd23ptMClMni+iNfs2DUPzCVHvYTSzBkXn2edGuF2WYDvNdvN5/X4154TIjhhR9XaSmQnsmOC08wy6U/hi7awQjw5p4jGxaGSDk6c5HjdiEUo37EVJYd+1CL2BPZtRU+TPDv1PpDJXmn7+EhUZonhAvB+G82uJ79C53LZavg1Svd7MmPH87qSUl+dFgnfMXdeWbGFsTUc+GPefcM3bk99XPDKvjBcDOLsLajlv5y4c= sileanth@delik"
	];
};
	};


	services.openssh.extraConfig = ''
Match User im-tunnel
	AllowTcpForwarding yes
	X11Forwarding no
	PermitTunnel no
	GatewayPorts yes
	AllowAgentForwarding no
	PermitOpen localhost:2222 141.148.238.80:2222
	ForceCommand echo 'This account is restricted for ssh reverse tunnel use
'';

}
