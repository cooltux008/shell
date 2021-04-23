#!/bin/sh
src_registry=yourdomain.com
dst_registry=mydomain.com:8443
repos=(
calico/typha
calico/cni
calico/pod2daemon-flexvol
calico/node
calico/kube-controllers
calico/ctl
google_containers/metrics-server-amd64
google_containers/addon-resizer
google_containers/pause-amd64
kubernetesui/dashboard
kubernetesui/metrics-scraper
coredns/coredns
coredns/cluster-proportional-autoscaler-amd64
ingress/controller
ingress/kube-webhook-certgen
)

for repo in ${repos[*]}
do
	docker run -i ananace/skopeo:latest sync \
	--src-creds=admin:Harbor12345 \
	--dest-creds=admin:Harbor12345 \
	--src-tls-verify=false \
	--dest-tls-verify=false \
	--src=docker \
	--dest=docker \
	$src_registry/$repo \
	$dst_registry/${repo%/*}
done
