#!/usr/bin/env python
#
# Author: Hans Chris Jones <chris.jones@lambdastack.io>
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import math
import glob
import os
from os import listdir
from os.path import isfile, join
import boto
import boto.s3.connection
from boto.s3.connection import Location
from boto.s3.bucket import Bucket

# NOTE: Modify these values with your key, secret and url/ip for s3 endpoint
access_key = "<whatever your access_key is>"
secret_key = "<whatever your secret_key is>"
endpoint = "<whatever your s3 url or IP is>"
admin_user = "<whatever your RGW admin user is>"

# NOTE: Add the proxy if you need one.

def connect(key, secret, host, proxy=None, user_agent=None, port=80,
            proxy_port=8080, is_secure=False, debug=0, verbose=False):
    conn = None

    try:
        conn = boto.connect_s3(
                    aws_access_key_id=key,
                    aws_secret_access_key=secret,
                    port=port,
                    host=host,
                    proxy=proxy,
                    proxy_port=proxy_port,
                    is_secure=is_secure,
                    calling_format=boto.s3.connection.OrdinaryCallingFormat(),
                    debug=debug)
        if conn and verbose:
            print('RGW Connected.')

    except BaseException, e:
        print(e.message)

    return conn


def bucket_handle(conn, bucket_name, validate=True, headers=None, create=False, make_public=False, verbose=False):
    if not conn or not bucket_name:
        if verbose:
            print('Connection and/or bucket name not valid - unable to get handle.')
        return None

    bucket = None

    try:
        bucket = conn.lookup(bucket_name, validate=validate, headers=headers)
        if not bucket and create:
            bucket = bucket_create(conn, bucket_name, headers=headers, make_public=make_public, verbose=verbose)  # add policy for acls
            if bucket:
                if verbose:
                    print('Bucket %s created.' % bucket_name)
            else:
                if verbose:
                    print('Bucket %s not created.' % bucket_name)
        else:
            if verbose:
                print('Bucket %s found.' % bucket_name)

        if bucket and make_public:  # temporary...
            bucket.make_public(recursive=False, headers=headers)
            if verbose:
                print('Bucket %s made public.' % bucket_name)
    except BaseException, e:
        print(e.message)

    return bucket


def bucket_create(conn, bucket_name, location=Location.DEFAULT, policy=None, headers=None, make_public=False, verbose=False):
    if not conn or not bucket_name:
        if verbose:
            print('Connection and/or bucket name not valid - unable to create.')
        return None

    bucket = None

    try:
        bucket = conn.create_bucket(bucket_name, location=location, policy=policy, headers=headers)
        if make_public:
            bucket.make_public(recursive=True, headers=headers)

        if bucket and verbose:
            print('Bucket %s created.' % bucket_name)
    except BaseException, e:
        print(e.message)

    return bucket


def bucket_list(bucket, verbose=False):
    if not bucket:
        if verbose:
            print('Bucket handle not valid.')
        return None

    try:
        for i in bucket.list():
            obj_name =  i.key.split("/")[-1]  # i.name  # i.key.split("/")[-1]
            size = i.size  # i.get_contents_to_filename(obj_name)
            print('%s: %d' % (obj_name, size))
    except BaseException, e:
        print(e.message)

    return None  # This is only a debug test function...


def object_create(bucket, name, string_value=None, file_name_path=None, make_public=False, headers=None, verbose=False):
    if not bucket or not name or (string_value is None and file_name_path is None):
        if verbose:
            print('Bucket handle not valid OR string_value or file_name is empty.')
        return None

    key = None

    try:
        key = bucket.get_key(name)
        if not key:
            key = bucket.new_key(name)

        if key:
            if string_value:
                key.set_contents_from_string(string_value)

            if file_name_path:
                # Check the size of the file. If it's larger than xxx then do a multipart else do a normal set_content
                key.set_contents_from_filename(file_name_path)

            if key and make_public:
                key.make_public(headers=headers)
            if verbose:
                print('Object %s created/updated.' % name)
        else:
            if verbose:
                print('Object %s was not created/updated.' % name)
    except BaseException, e:
        print(e.message)

    return key


def object_delete(bucket, name, headers=None, version_id=None, mfa_token=None, verbose=False):
    if not bucket or not name:
        if verbose:
            print('Bucket and/or object name is not valid.')
        return None

    key_object = None

    try:
        key_object = bucket.delete_key(name, headers=headers, version_id=version_id, mfa_token=mfa_token)
        if verbose:
            print('Object %s deleted.' % name)
    except BaseException, e:
        print(e.message)

    return key_object


def object_get(bucket, name, file_name_path, headers=None, version_id=None, response_headers=None, verbose=False):
    if not bucket or not name:
        if verbose:
            print('Bucket and/or object name is not valid.')
        return None

    if not file_name_path:
        file_name_path = name

    key_object = None

    try:
        key_object = bucket.get_key(name, headers=headers, version_id=version_id, response_headers=response_headers)
        key_object.get_contents_to_filename(file_name_path)
        if verbose:
            print('Retrieved object %s.' % name)
    except BaseException, e:
        print(e.message)

    return key_object


def object_url(bucket, name, signed_duration=0, query_auth=False, force_http=False, verbose=False):
    """
    :param bucket:
    :param name:
    :param signed_duration:
    :param query_auth:
    :param force_http: default is False so that the port is included if the port is not 80
    :param verbose:
    :return: url
    """
    if not bucket or not name:
        if verbose:
            print('Bucket and/or object name is not valid.')
        return None

    url = None

    try:
        if signed_duration < 0:
            signed_duration = 0
        if signed_duration > 0 and query_auth is False:
            query_auth = True
        key_object = bucket.get_key(name)
        # If the signed_duration is > than 0 then assume a signed url with signed_duration the amount of time the url
        # is valid.
        url = key_object.generate_url(signed_duration, query_auth=query_auth, force_http=force_http)
        if url and verbose:
            print('Generated %s' % url)
    except BaseException, e:
        print(e.message)

    return url


def upload_directory(bucket, directory, pattern='*', include_dir_prefix=False, make_public=False, verbose=False):
    if not bucket or not directory:
        if verbose:
            print('Bucket and/or directory name is not valid.')
        return None

    # One way
    # files = [f for f in listdir(directory) if isfile(join(directory, f))]

    # Using glob allows for simple patterns and no hidden files...
    files = glob.glob(os.path.join(directory, pattern))
    files = [f for f in files if isfile(f)]  # Scrub the list for only files
    file_names = [f.split('/')[-1] for f in files]

    if verbose:
        print('Directory list obtained and scrubbed.')

    key_objects = []

    count = 0
    for file_name in file_names:
        key_objects.append(object_create(bucket, file_name, file_name_path=files[count], make_public=make_public, verbose=verbose))
        if verbose:
            print('File: %s uploaded.' % file_name)
        count += 1

    return key_objects


# NB: Create a Tenancy (user) using the RGW API which is part of RGW on the same port(s).
# NB: *MUST USE* user with admin caps such as the default 'radosgw' user ceph-chef creates by default.
def user_create(conn, admin_user, user_name, display_name, caps=None, verbose=False):
    if not conn or not user_name:
        if verbose:
            print('Connection and/or user name not valid - unable to create.')
        return None

    user = None

    try:
        print "/%s/user?format=json&uid=%s&display-name='%s'" % (admin_user, user_name, display_name)

        resp = conn.make_request("PUT", query_args="/%s/user?format=json&uid=%s&display-name='%s'" % (admin_user, user_name, display_name))

        if resp:
            print resp.status
            print resp.read()

        if user and verbose:
            print('User %s created.' % user_name)
    except BaseException, e:
        print(e.message)

    return user



def main():
    # NOTE: This is just a number of samples that can be called via the cli. However, the primary purpose of this
    # are the functions defined above which are imported into rgw-admin.py

    conn = connect(key, secret, is_secure=False, verbose=True)  # debug=2 Add more options later...

    # Sample header for object_get
    # headers={'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8', 'Accept-Encoding': 'gzip, deflate, sdch', 'Accept-Language': 'en-US,en;q=0.8'}
    bucket = bucket_handle(conn, 'bcs-test', make_public=True, validate=True, create=True, verbose=True)

    object_create(bucket, 'hello1.txt', string_value='Hello everyone :)', make_public=True, verbose=True)
    # file_name_path = 'eabbcab9-1d30-4218-ad78-640f234463d0_2400.mp4'
    # file_name = file_name_path.split('/')[-1]
    # object_create(bucket,file_name, file_name_path=file_name_path, make_public=True, verbose=True)
    bucket_list(bucket, verbose=True)
    # object_delete(bucket, 'hello.txt', verbose=True)

    # Example usage:
    key_object = object_get(bucket, 'hello1.txt', 'hello1.txt', verbose=True)

    # upload_directory(bucket, '<directory>', make_public=True, verbose=True)
    # print object_url(bucket, 'test_video.mp4')
    print object_url(bucket, 'hello1.txt', signed_duration=60)

if __name__ == "__main__":
    main()
