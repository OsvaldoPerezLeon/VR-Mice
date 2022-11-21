function test_licometer_v5
% incluye salida grafica del canal del circuito
% incluye medidor de frecuencia de muestreo

%___________________________________________________________
% % % change reference voltage for analog pins to external
% analogReference(a,'external');
% 
% % change it back to default
% analogReference(a,'default');
%___________________________________________________________


% SKETCH COMPILED: adioes.pde
% arduino_board=arduino('COM10');
% delete(instrfind({'Port'},{'COM10'}))
global arduino_board is_licking is_relicking
global pin_salida_1 pin_salida_2 pin_salida_3
global pin_entrada_analogico_1 pin_entrada_analogico_2 pin_entrada_analogico_3
% LEEMOS informacion de la tarjeta
arduino_board=evalin('base', 'arduino_board');

% USER INPUT
%_______________________________________________________
% en la arduino receptora
pin_entrada_analogico_1=0; % entrada analogica 1
pin_entrada_analogico_2=1; % entrada analogica 2
pin_entrada_analogico_3=2; % entrada analogica 3

pin_salida_1=11; % salida digital 1
pin_salida_2=12; % salida digital 1
pin_salida_3=13; % salida digital 1

n_cycles=2000;
lw=3;
umbral=500; % X 1024/5 = volts
delta_window_x=100/2; % + -  eje de X
num_cum_frames=2; % number of accumulative frames to turn variables ON
%_______________________________________________________

licked_port=0; % inicializado a cero

time_vector=ones(n_cycles,1).*NaN;

% INICIALIZAMOS VARIABLES
arduino_board.pinMode(pin_salida_1,'output');
arduino_board.pinMode(pin_salida_2,'output');
arduino_board.pinMode(pin_salida_3,'output');


all_valves(1); % abre las valvulas para meter el tubing a los solenoides
all_valves(0); % cierra las valvulas

drenado; % funcion de DRENADO, se abren las valvulas hasta presionar una tecla�

is_licking=0; % the mouse is NOT likcing
sensor_licking=0;

% OJO en la arduino emisora:
% arduino_board.pinmode(14,'output'); % se define canal de comunicacion de salida
% arduino_board.digitalWrite(14,0); % apaga led
% arduino_board.digitalWrite(14,1); % enciende led

%definimos pin de entrada y salida
% arduino_board.pinMode(pin_entrada,'input');
%%allocate variable
valor=ones(n_cycles,3).*NaN;


tic
for i=1:n_cycles

valor(i,1)=analogRead(arduino_board,pin_entrada_analogico_1);
valor(i,2)=analogRead(arduino_board,pin_entrada_analogico_2);
valor(i,3)=analogRead(arduino_board,pin_entrada_analogico_3);

putative_closed_channel=find(valor(i,:)==min(valor(i,:)));
%encuentra el valor m�nimo "tierra" licometro activado
hold on
plot(valor(:,1), 'r', 'Linewidth', lw)
plot(valor(:,2), 'g', 'Linewidth', lw)
plot(valor(:,3), 'b', 'Linewidth', lw)
xlim([i-delta_window_x i+delta_window_x])
ylim([0 1200])
drawnow

% __________________________________________________________________________
% 1: is the mouse licking?
if (valor(i,putative_closed_channel)<umbral)
    %     MOUSE IS LICKING ONE PORT
    sensor_licking=sensor_licking+1;
    if sensor_licking>=num_cum_frames
        is_licking=1; % The mouse is licking
        
        % hacer is_relicking cero cuando el raton CAMBIA de puerto
        if putative_closed_channel~=licked_port
            is_relicking=0; % start things from fresh
        end
        
    end
else % MOUSE IS not LICKING ANY PORT
    arduino_board.digitalWrite(pin_salida_1,0); % LED OFF: Mouse NOT Likcing
    arduino_board.digitalWrite(pin_salida_2,0);
    arduino_board.digitalWrite(pin_salida_3,0);
    is_licking=0; % The mouse is NOT licking
    sensor_licking=0; %se reinicia la bandera
end

% % is the mother fucker re-liking?
% if putative_closed_channel==licked_port
% is_relicking=1;    
% else
% is_relicking=0;      
% end



% __________________________________________________________________________
% 2: which port is it licking?
if is_licking&not(is_relicking)
    
if putative_closed_channel==1
         open_valve(1)
         disp('Sensor_1')
         licked_port=1; % which port is licking right now?
elseif putative_closed_channel==2
        open_valve(2)
        disp('Sensor_2')
        licked_port=2; % which port is licking right now?
elseif putative_closed_channel==3
        open_valve(3)
        disp('Sensor_3')
        licked_port=3; % which port is licking right now?
end
end
% __________________________________________________________________________

time_vector(i,1)=toc;

end
%"nanmean" promedio ignorando los Nan.
frecuencia_muestreo=1./nanmean(diff(time_vector)) % en Hz
% arduino_board.pinMode(12,'output')
% arduino_board.digitalWrite(12,1)

function open_valve(valve_number)
global pin_salida_1 pin_salida_2 pin_salida_3
global pin_entrada_analogico_1 pin_entrada_analogico_2 pin_entrada_analogico_3
global arduino_board is_relicking
global i % para incrementar counter dentro de la funcion!!!

if valve_number==1
    pin=pin_salida_1;
elseif valve_number==2
    pin=pin_salida_2;
else
    pin=pin_salida_3;
end

frames_on=10;
cycles=2; % abrir y cerrar valvulas solenoides

for c=1:cycles
    % OPEN VALVE
    for jj=1:frames_on
        arduino_board.digitalWrite(pin,1); % LED ON: Mouse Likcingsensor
        % LEEMOS DATOS
        valor(i,1)=analogRead(arduino_board,pin_entrada_analogico_1);
        valor(i,2)=analogRead(arduino_board,pin_entrada_analogico_2);
        valor(i,3)=analogRead(arduino_board,pin_entrada_analogico_3);
        
        time_vector(i,1)=toc;
        i=i+1;
    end
    % CLOSE VALVE
    for jj=1:frames_on
        arduino_board.digitalWrite(pin,0); % LED OFF: Mouse Likcingsensor
        % LEEMOS DATOS
        valor(i,1)=analogRead(arduino_board,pin_entrada_analogico_1);
        valor(i,2)=analogRead(arduino_board,pin_entrada_analogico_2);
        valor(i,3)=analogRead(arduino_board,pin_entrada_analogico_3);
        time_vector(i,1)=toc;
        i=i+1;
    end
    
end

is_relicking=1; % aqui activamos 'is_relicking' para que se cierre la valvula


function all_valves(boolean_switch)
% 0: cierra la valvula, 1: abre la valvula
global arduino_board 
global pin_salida_1 pin_salida_2 pin_salida_3

arduino_board.digitalWrite(pin_salida_1,boolean_switch); % apagamos led
arduino_board.digitalWrite(pin_salida_2,boolean_switch); % apagamos led
arduino_board.digitalWrite(pin_salida_3,boolean_switch); % apagamos led

function drenado
global arduino_board 
global pin_salida_1 pin_salida_2 pin_salida_3

KeyIsDown=0;
while KeyIsDown~=1
[KeyIsDown, endrt, KeyCode]=KbCheck;
arduino_board.digitalWrite(pin_salida_1,1); % valvula abierta
arduino_board.digitalWrite(pin_salida_2,1); 
arduino_board.digitalWrite(pin_salida_3,1); 
% KeyIsDown
end

arduino_board.digitalWrite(pin_salida_1,0); % valvula cerrada
arduino_board.digitalWrite(pin_salida_2,0); 
arduino_board.digitalWrite(pin_salida_3,0)

 