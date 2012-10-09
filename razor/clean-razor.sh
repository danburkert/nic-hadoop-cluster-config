razor active_model remove all
razor model remove all
razor broker remove all
razor policy remove all
image_uuids=`razor image | grep UUID | awk '{print $3}'`
for uuid in $image_uuids; do
  razor image remove $uuid
done
