# Copyright 2023 camoes
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import boto3
import botocore
boto3.set_stream_logger(name='botocore')  # this enables debug tracing
session = boto3.session.Session()
s3_client = session.client(
    service_name='s3',
    aws_access_key_id='d23b989431f54cf3a403507ee7016140',
    aws_secret_access_key='1be9383896ed44f1881f6c17a116dc17',
    endpoint_url='https://object.cscs.ch:443/v1/AUTH_557cd33c814f42e4b901b547bafdbcbd',
    # The next option is only required because my provider only offers "version 2"
    # authentication protocol. Otherwise this would be 's3v4' (the default, version 4).
    config=botocore.client.Config(signature_version='s3'),
)

s3_client.list_buckets()