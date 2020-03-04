import requests
from requests.auth import HTTPBasicAuth
auth = HTTPBasicAuth('gerrit','92+Yvl2Yh79pyEpuolil+i8qWDqVsW5Lmhz38wZfEQ')
r = requests.get('http://192.168.56.101:8088/a/config/server/tasks',auth=auth)
print(r.text)