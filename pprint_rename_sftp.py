#Libraries 
import lxml
import os
import re
import pysftp
from lxml import etree
from xml.etree import ElementTree
from datetime import datetime

#Variables
mainpath = r"\\testfiles"
nsmap = "{urn:hl7-org:v3}"
#The following example could be use as wilds {*} if we didnt know the xml namespace
#xpath = './/{*}component/{*}structuredBody/{*}component/{*}section/{*}title'
xpath = './/'+nsmap+'component/'+nsmap+'structuredBody/'+nsmap+'component/'+nsmap+'section/'+nsmap+'entry/'+nsmap+'act/'+nsmap+'entryRelationship/'+nsmap+'encounter'
xpath_code = xpath+"/"+nsmap+"code"
hospitalId = "000000"
file_type = "naming"
outputfolder = r"\\output"


#TEST WORKING WITH THE WHOLE DIRECTORY
for files in os.listdir(mainpath):
    filename = os.fsdecode(files)
    #print(files)
    #print(filename)
    print(os.path.join(mainpath, filename))
    maintree = etree.parse(os.path.join(mainpath, filename))
    print(maintree)
    #tree = etree.parse(files)
    root = maintree.getroot()
    print (maintree)
    for inside in root.findall(xpath_code):
        print("inside.attrib", inside.attrib['code'])
        if inside.attrib['code'] == '32485007':
            print ("found Inpatient Data")
            low = xpath+'/'+nsmap+'effectiveTime/'+nsmap+'low'
            high = xpath+'/'+nsmap+'effectiveTime/'+nsmap+'high'
        for node in root.findall(low):
            lowvar = node.attrib['value']
            print (lowvar)
        for node in root.findall(high):
            highvar = node.attrib['value']
            print (node.attrib['value'])
    #Split the file and capture the MRI
    split = re.split("[_.]", os.path.join(mainpath, filename))[-2]
    print(split)
    #Create a variable to hold the new filename
    filename = hospitalId+"_"+file_type+"_"+lowvar+"_"+"_"+highvar+"_"+split
    #print(filename)
    #pretty_print the xml file before saving to a file 
    pretty = lxml.etree.tostring(maintree, encoding="unicode", pretty_print=True)
    outputpath = r"C:\\output\{}.xml".format(filename)
    f= open(outputpath,"w")
    f.write(pretty)
    #good practice
    f.close()

#SFTP files to processing servers
for outfiles in os.listdir(outputfolder):
    print (outfiles)
    #connect to SFTP archive
    cnopts = pysftp.CnOpts()
    cnopts.hostkeys = None
    sftp = pysftp.Connection(host='server', username='user', password='password', cnopts=cnopts)
    #sftp.chdir('/ihm-storage/mu/inbox/new')
    sftp.cd('/ihm-storage/mu/inbox/new')
    
    sftp.put("file")
    sftp.close()
    
