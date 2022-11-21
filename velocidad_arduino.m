diametro=24;
divisiones=20;
% en total son 40.
circ= pi*diametro;
dist=circ/divisiones;
actual=a.analogRead(0)*5/1023;

old=0;
now=a.analogRead(0);
old =now;


