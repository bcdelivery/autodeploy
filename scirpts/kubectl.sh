docker tag quay-mirror.qiniu.com/cortexproject/ruler:master-4c0719ca          quay.io/cortexproject/ruler:latest
docker tag quay-mirror.qiniu.com/cortexproject/table-manager:master-4c0719ca          quay.io/cortexproject/table-manager:latest
docker tag quay-mirror.qiniu.com/cortexproject/querier:master-4c0719ca          quay.io/cortexproject/querier:latest
docker tag quay-mirror.qiniu.com/cortexproject/configs:master-4c0719ca          quay.io/cortexproject/configs:latest
docker tag quay-mirror.qiniu.com/cortexproject/distributor:master-4c0719ca          quay.io/cortexproject/distributor:latest
docker tag quay-mirror.qiniu.com/cortexproject/alertmanager:master-4c0719ca          quay.io/cortexproject/alertmanager:latest
docker tag quay-mirror.qiniu.com/cortexproject/query-frontend:master-4c0719ca          quay.io/cortexproject/query-frontend:latest
docker tag quay-mirror.qiniu.com/cortexproject/ingester:master-4c0719ca          quay.io/cortexproject/ingester:latest
docker tag quay-mirror.qiniu.com/cortexproject/test-exporter:master-4c0719ca          quay.io/cortexproject/test-exporter:latest
docker tag quay-mirror.qiniu.com/cortexproject/lite:master-4c0719ca          quay.io/cortexproject/lite:latest


docker pull postgres:9.6
docker pull consul:0.7.1
docker pull deangiberson/aws-dynamodb-local:latest
docker pull memcached:1.4.25
docker pull nginx:latest
docker pull lphoward/fake-s3:latest


docker pull registry.aliyuncs.com/google_containers/k8s-dns-dnsmasq-amd64:1.14.5

docker tag docker.io/ist0ne/kubedns-amd64:1.9 gcr.io/google_containers/kubedns-amd64:1.9
docker tag docker.io/ist0ne/dnsmasq-metrics-amd64:1.0 gcr.io/google_containers/dnsmasq-metrics-amd64:1.0.1
docker tag docker.io/ist0ne/exechealthz-amd64:1.2 gcr.io/google_containers/exechealthz-amd64:1.2

docker tag docker.io/sapcc/k8s-dns-kube-dns-amd64 gcr.io/google_containers/k8s-dns-dnsmasq-amd64:1.14.5


docker pull quay-mirror.qiniu.com/cortexproject/ruler:master-4c0719ca         
docker pull quay-mirror.qiniu.com/cortexproject/table-manager:master-4c0719ca  
docker pull quay-mirror.qiniu.com/cortexproject/querier:master-4c0719ca       
docker pull quay-mirror.qiniu.com/cortexproject/configs:master-4c0719ca       
docker pull quay-mirror.qiniu.com/cortexproject/distributor:master-4c0719ca    
docker pull quay-mirror.qiniu.com/cortexproject/alertmanager:master-4c0719ca   
docker pull quay-mirror.qiniu.com/cortexproject/query-frontend:master-4c0719ca 
docker pull quay-mirror.qiniu.com/cortexproject/ingester:master-4c0719ca      
docker pull quay-mirror.qiniu.com/cortexproject/test-exporter:master-4c0719ca  
docker pull quay-mirror.qiniu.com/cortexproject/lite:master-4c0719ca          
