import serial #cargamos la libreria serial
 
ser = serial.Serial('COM3', 9600) #inicializamos el puerto de serie a 9600 baud
 
#variable para almacenar el mensaje
#le asignamos un valor introducido por el usuario
print ("Introduce un caracter ('s' para salir): ")
entrada = input()
 
while entrada != 's': #introduciendo 's' salimos del bucle
 
   ser.write(entrada) #envia la entrada por serial
   print ("He enviado: ", entrada)
   print ("Introduce un caracter ('s' para salir): ")
 
   entrada = input() #introduce otro caracter por teclado



