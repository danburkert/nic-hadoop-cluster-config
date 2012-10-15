### Add Images
image_type='os'
image_path='/opt/image/CentOS-6.3-x86_64-minimal.iso'
image_name='centos_6'
image_version='6'

image_uuid=`razor image add -t ${image_type} -p ${image_path} \
  -n ${image_name} -v ${image_version} \
  | grep UUID | awk '{ print $3 }'`
echo "Image uuid: ${image_uuid}"

mk_type='mk'
mk_path='/opt/image/rz_mk_prod-image.0.9.1.6.iso'
mk_uuid=`razor image add -t ${mk_type} -p ${mk_path} \
  | grep UUID | awk '{ print $3 }'`
echo "mk uuid: ${mk_uuid}"

### Create Model
model_template='nic_hadoop_centos_6'
model_label='nic-hadoop-model'
model_image=${image_uuid}

model_uuid=`razor model add -t ${model_template} -l ${model_label} \
  -i ${model_image} \
  | grep UUID | awk '{ print $3 }'`
echo "model uuid: ${model_uuid}"

### Create Model
policy_template='linux_deploy'
policy_label='nic-hadoop-policy'
policy_model=${model_uuid}
policy_tags='Supermicro'
policy_enabled='true'

policy_uuid=`razor policy add -p ${policy_template} -l ${policy_label} \
  -m ${policy_model} -t ${policy_tags} -e ${policy_enabled}\
  | grep UUID | awk '{ print $3 }'`
echo "policy uuid: ${policy_uuid}"

### Configure iPXE settings
sudo razor config ipxe > /var/lib/tftpboot/razor.ipxe
