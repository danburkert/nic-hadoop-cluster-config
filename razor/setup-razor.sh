### Add Images
ubuntu_type='os'
ubuntu_path='/opt/image/ubuntu-12.04.1-server-amd64.iso'
ubuntu_name='ubuntu-precise'
ubuntu_version='precise'

ubuntu_uuid=`razor image add -t ${ubuntu_type} -p ${ubuntu_path} \
  -n ${ubuntu_name} -v ${ubuntu_version} \
  | grep UUID | awk '{ print $3 }'`
echo "Ubuntu uuid: ${ubuntu_uuid}"

mk_type='mk'
mk_path='/opt/image/rz_mk_prod-image.0.9.0.4.iso'
mk_uuid=`razor image add -t ${mk_type} -p ${mk_path} \
  | grep UUID | awk '{ print $3 }'`
echo "mk uuid: ${mk_uuid}"

### Create Broker
broker_plugin='puppet'
broker_name='puppet'
broker_description='puppet with version'
broker_server='nic-hadoop-puppet.nearinfinity.com'
broker_version='2.7.19'

broker_uuid=`razor broker add -p ${broker_plugin} -n ${broker_name} \
  -d ${broker_description} -s ${broker_server} -v ${broker_version} \
  | grep UUID | awk '{ print $3 }'`
echo "broker uuid: ${broker_uuid}"

### Create Model
model_template='nic_hadoop_ubuntu_precise'
model_label='nic-hadoop-model'
model_image=${ubuntu_uuid}

model_uuid=`razor model add -t ${model_template} -l ${model_label} \
  -i ${model_image} \
  | grep UUID | awk '{ print $3 }'`
echo "model uuid: ${model_uuid}"

### Create Model
policy_template='linux_deploy'
policy_label='nic-hadoop-policy'
policy_model=${model_uuid}
policy_broker=${broker_uuid}
policy_tags='Supermicro'
policy_enabled='true'

policy_uuid=`razor policy add -p ${policy_template} -l ${policy_label} \
  -m ${policy_model} -b ${policy_broker} -t ${policy_tags} -e ${policy_enabled}\
  | grep UUID | awk '{ print $3 }'`
echo "policy uuid: ${policy_uuid}"
