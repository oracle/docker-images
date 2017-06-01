import os
import socket

# Variables
# =========
# Environment Vars
hostname       = socket.gethostname()
# Admin Vars
admin_username = os.environ.get('ADMIN_USERNAME', 'weblogic')
admin_password = os.environ.get('ADMIN_PASSWORD') # this is read only once when creating domain (during docker image build)
admin_host     = os.environ.get('ADMIN_HOST', 'wlsadmin')
admin_port     = os.environ.get('ADMIN_PORT', '8001')
administration_port = os.environ.get('ADMINISTRATION_PORT', '9002')
# Node Manager Vars
nmname         = os.environ.get('NM_NAME', 'Machine-' + hostname)

# Functions
def editMode():
    edit()
    startEdit(waitTimeInMillis=-1, exclusive="true")

def saveActivate():
    save()
    activate(block="true")

def connectToAdmin():
    connect(url='t3s://' + admin_host + ':' + administration_port, adminServerName='AdminServer')
