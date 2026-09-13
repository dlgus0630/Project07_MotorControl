function [u,integ,df,yp] = pid_fixed(ref,y,integ,df,yp)
e=ref-y; df=floor((3*df+y-yp)/4); yp=y;
p=floor(58982*e/65536); d=0;
candidate=max(-4096,min(4096,integ+floor(3932*e/65536)));
raw=p+candidate-d;
if ~((raw>4096 && e>0)||(raw<0 && e<0)), integ=candidate; end
u=max(0,min(4096,p+integ-d));
end
