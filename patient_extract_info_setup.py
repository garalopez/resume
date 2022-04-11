'''
Descritpion:
The purpose of this script is to get a file from a server based on the location given by the user (folder), account to look for (acct) and name of the file (file_name)
After parsing this will print all the section that contain the account info in question

'''


import lxml
import os
import re
import pysftp
import base64
import time
from lxml import etree
from xml.etree import ElementTree


# variables
mainpath = r"/serverpath/"
acct = "acct"
folder = "directory_number"
file_name = "filename.xml"
#ftp settings
cnopts = pysftp.CnOpts()
cnopts.hostkeys = None 
#connect to ftp01 
ftp01 = pysftp.Connection(host='server_to_connect', username='user', password=base64.b64decode('UGFzc3dvcmQNCg==').decode('utf-8'), cnopts=cnopts)
ftp01.chdir('/serverpath/{0}'.format(folder))
start_time = time.time()
serverpath = ftp01.listdir()

def print_parent(nodes):
    for node in nodes:
        if node.text == adm_urn:
            parent = node.getparent()
            print(etree.tostring(parent,encoding="unicode", pretty_print=True))

foundfile = r'/serverpath/{0}/{1}'.format(folder,file_name)                
filename = os.fsdecode(foundfile)
#join = foundfile
join = filename
#os.path.join(mainpath, folder, filename)
print (join)
maintree = etree.parse(ftp01.open(join))
print("--- %s seconds mainttree ---" % (time.time() - start_time))
#maintree = etree.parse(file)
root = maintree.getroot()
print("--- %s seconds root---" % (time.time() - start_time))
abslevel = root.findall('.//abs')
for abspat in abslevel:
    find = abspat.findall('account.number')
    for node in find:
        if node.text == acct:
            prev = node.xpath('preceding-sibling::urn')
            for adm in prev:
                urn = adm.text
            parent = node.getparent()
            print(etree.tostring(parent,encoding="unicode", pretty_print=True))
admlevel = root.findall('.//adm')
for admpat in admlevel:
    admurn_adm = admpat.findall('urn')
    print_parent(admurn_adm)
barlevel = root.findall('.//bar')
for barpat in barlevel:
    admurn_bar = barpat.findall('urn')
    print_parent(admurn_bar)
labllevel = root.findall('.//lab')
for labl in labllevel:
    admurn_labl = labl.findall('urn')
    print_parent(admurn_labl)
labblevel = root.findall('.//lab')
for labb in labblevel:
    admurn_labb = labb.findall('urn')
    print_parent(admurn_labb)
labmlevel = root.findall('.//lab')
for labm in labmlevel:
    admurn_labm = labm.findall('urn')
    print_parent(admurn_labm)
pharxlevel = root.findall('.//pha')
for pharx in pharxlevel:
    admurn_pharx = pharx.findall('urn')
    print_parent(admurn_pharx)
radreslevel = root.findall('.//rad')
for radres in radreslevel:
    admurn_radres = radres.findall('urn')
    print_parent(admurn_radres)
schpatlevel = root.findall('.//sch')
for schpat in schpatlevel:
    admurn_schpat = schpat.findall('urn')
    print_parent(admurn_schpat)
        
print("--- %s seconds ---" % (time.time() - start_time))
#Close FTP connections
ftp01.close() 
