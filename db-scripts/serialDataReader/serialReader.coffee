{SerialPort, parsers} = require 'serialport'


main = -> 
	port = {}
	portIsOpenCallback = ->
		port.on 'data', (data) -> console.log data+"\n"
		

	port = new SerialPort("/dev/ttyACMO", {parser:parsers.readline('\n')}, portIsOpenCallback)





main()
