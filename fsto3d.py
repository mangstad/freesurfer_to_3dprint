import pandas as pd

if __name__ == "__main__":
    print "test"

#takes input r/g/b values and combines into 24bit value
def color_to_24bit(r,g,b):
    return int(r)*65536+int(g)*256+int(b)

def parse_ctab_line(line):
    fields = line.split()
    return fields[1] + " " + str(color_to_24bit(fields[2],fields[3],fields[4]))

def parse_ctab(filename):
    output = list()
    with open(filename,'r') as file:
        for line in file:
            output.append(parse_ctab_line(line))
    return output

def convert_ctab(in_file,out_file):
    ctab = parse_ctab(in_file)
    with open(out_file,'w') as file:
        for line in ctab:
            file.write(line + '\n')

def combine_asc_color(asc_file,color_file,out_file):
    with open(asc_file,'r') as file:
        hdr = file.readline()
        (nV,nF) = [int(x) for x in file.readline().split()]
    asc = pd.read_table(asc_file,sep='\s+',skiprows=2,header=None)
    asc = asc.drop(asc.columns[3],axis=1)
    color = pd.read_table(color_file,sep='\s+',header=None)
    color = color.drop(color.columns[[0,1,2,3]],axis=1)
    color = pd.concat([color,(color.iloc[:,0] // (256*256))/255],axis=1)
    color = pd.concat([color,((color.iloc[:,0] % (256*256))//256)/255],axis=1)
    color = pd.concat([color,(color.iloc[:,0] % 256)/255],axis=1)
    color.columns = [1,2,3,4]
    color = color.drop(color.columns[0],axis=1)
    output = pd.concat([asc,color],axis=1)
    output.fillna(0,inplace=True)
    file = open(out_file,'w')
    file.write(hdr)
    file.write(str(nV) + ' ' + str(nF) + '\n')
    file.close()
    output.to_csv(out_file,header=None,index=None,sep=' ',mode='a')
    
