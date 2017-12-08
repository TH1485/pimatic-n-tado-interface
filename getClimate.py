
from interface import Tado
import sys, json

#Read data from stdin
def read_in():
    lines = ""
	
    for line in sys.stdin.readlines():
        lines += line
	#Since our input would only be having one line, parse our JSON data from that
        return lines

def main():
    #get our data as an array from read_in()
    lines = read_in()
    # create tado
    if 'login' in lines and 'password' in lines:
        jsonLines = json.loads(lines)
        t = Tado(jsonLines["login"],jsonLines["password"])
	    #weather = t.getWeather()
        zone = 1
        if 'zone' in lines:
            zone = jsonLines["zone"] 
        climate = t.getClimate(zone)
        #print(json.dumps(climate,indent=2))
        #print(json.dumps(weather,indent=2))
        #return the sum to the output stream
    else:
        climate = {'temperature' : 0, 'humidity' : 0}
    print(json.dumps(climate))

#start process
if __name__ == '__main__':
    main()

