#!/usr/bin/env python3
# Description: check EBS status
# Author: Claudiu Tomescu
# E-mail: klau2005@gmail.com
# June 2016

# define the variables
service_order_ID=$(date +%Y%m%d%H%M%s%N)
msisdn="<MSISDN>"
iccid="<ICCID>"
card_profile="<CP>"
delete_url="<URL>"
create_url="<URL>"

# define the create function
ebs_create() {
cat << EOF > /tmp/create_${service_order_ID}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:root="URL">
<soapenv:Header/>
<soapenv:Body>
<root:DeliverServiceOrder>
<ServiceOrder>
<serviceOrderID>${service_order_ID}</serviceOrderID>
<!--1 or more repetitions:-->
<ServiceOrderItem>
<serviceOrderItemID>20150109000001</serviceOrderItemID>
<ServiceSpecOperation>
<operationCode>Create</operationCode>
<!--Optional:-->
<Local_ServiceSpecOperationOrigin>
<originCode/><originLabel/>
</Local_ServiceSpecOperationOrigin>
</ServiceSpecOperation>
<!--Optional:-->
<ServiceSpecification>
<serviceSpecificationType>ResourceFacingService</serviceSpecificationType>
<specificationCode>NFCService</specificationCode>
</ServiceSpecification>
<!--Optional:-->
<InstalledService>
<!--Optional:-->
<ServiceSpecification>
<serviceSpecificationType>ResourceFacingService</serviceSpecificationType>
<specificationCode/>
</ServiceSpecification>
<!--Optional:-->
<InstServiceCharacteristicValue>
<characteristicValue/>
<ServiceSpecCharacteristic>
<characteristicCode/>
</ServiceSpecCharacteristic>
</InstServiceCharacteristicValue>
<!--Optional:-->
<Local_InstalledResource>
<!--Zero or more repetitions:-->
<InstalledResourceCharValue>
<characteristicValue>${iccid}</characteristicValue>
<ResourceSpecCharacteristic>
<characteristicCode>ICCID</characteristicCode>
</ResourceSpecCharacteristic>
<!--Optional:-->
<InstalledResourceCharValueLink>
<characteristicCode/>
</InstalledResourceCharValueLink>
</InstalledResourceCharValue>
<!--Optional:-->
<InstalledResourceCharValue>
<characteristicValue>${card_profile}</characteristicValue>
<ResourceSpecCharacteristic>
<characteristicCode>SIMCardProfileID</characteristicCode>
</ResourceSpecCharacteristic>
<InstalledResourceCharValueLink>
<characteristicCode>SIMCardProfileID</characteristicCode>
</InstalledResourceCharValueLink>
</InstalledResourceCharValue>
<InstalledResourceCharValue>
<characteristicValue>11223344</characteristicValue>
<ResourceSpecCharacteristic>
<characteristicCode>TAC</characteristicCode>
</ResourceSpecCharacteristic>
<!--Optional:-->
<InstalledResourceCharValueLink>
<characteristicCode/>
</InstalledResourceCharValueLink>
</InstalledResourceCharValue>
</Local_InstalledResource>
</InstalledService>
<!--Optional:-->
<ServiceSpecCharacteristicValue>
<characteristicValue>${msisdn}</characteristicValue>
<ServiceSpecCharacteristic>
<characteristicCode>MSISDN</characteristicCode>
<!--Optional:-->
<ServiceSpecCharactOperation>
<operationCode>Change</operationCode>
</ServiceSpecCharactOperation>
</ServiceSpecCharacteristic>
</ServiceSpecCharacteristicValue>
<!--Optional:-->
<User>
<!--Optional:-->
<Local_Person>
<!--Optional:-->
<language>French</language>
<PersonName>
<!--Optional:-->
<salutation>Mr</salutation>
<!--Optional:-->
<firstName>Oberthur Dummy User</firstName>
<lastName>Oberthur Dummy User</lastName>
</PersonName>
</Local_Person>
</User>
</ServiceOrderItem>
</ServiceOrder>
</root:DeliverServiceOrder>
</soapenv:Body>
</soapenv:Envelope>
EOF
curl -s -X POST -w %{http_code} --insecure --header "content-type: text/soap+xml; charset=utf-8" --data @/tmp/create_${service_order_ID} ${create_url}
}

# define the delete function
ebs_delete() {
cat << EOF > /tmp/delete_${service_order_ID}
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="URL"><soapenv:Header/><soapenv:Body><ws:deleteCustomerAndSimCardServices>
<msisdn>${msisdn}</msisdn>
</ws:deleteCustomerAndSimCardServices>
</soapenv:Body>
</soapenv:Envelope>
EOF
curl -s -X POST -w %{http_code} --insecure --header "content-type: text/soap+xml; charset=utf-8" --data @/tmp/delete_${service_order_ID} ${delete_url}
}

# run the functions and save HTTP response codes in variables
ebs_create_result=$(ebs_create | sed -n 's/^<.*>\(.*$\)/\1/p')
ebs_delete_result=$(ebs_delete | sed -n 's/^<.*>\(.*$\)/\1/p')

# check the result codes, set exit status and compose plugin message
if [[ $ebs_create_result != 200 ]]
then
message="EBS create failed!"
status=2
elif [[ $ebs_delete_result != 200 ]]
then
message="EBS delete failed!"
status=2
else
message="EBS create/delete OK!"
status=0
fi

# compose message for the performance graphs in Centreon (TBD)
perf_message=0

# remove the temp files
rm /tmp/*_${service_order_ID}

printf "%s | %s" "${message}" "${perf_message}"
exit $status
