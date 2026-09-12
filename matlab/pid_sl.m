function v=pid_sl(u)
% u = reference, measured speed, previous [duty integral derivative measured].
[a,b,c,d]=pid_fixed(u(1),u(2),u(4),u(5),u(6)); v=[a;b;c;d];
end
