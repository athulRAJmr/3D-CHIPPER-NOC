module singleflit #(parameter xn=2'b00, parameter yn=2'b00, parameter zn=2'b00)(in, out);
input [31:0] in;
output reg [34:0]out;
                                 
always@(*)
begin
  if(in[29:28]>yn)                                            //ZXY routing algo for single flit 
        out = {3'b000, in};
  else if(in[29:28]<yn)                            /*  OUTPUT ENCODING : 000-N  001-S   010-E   011-W   100-U   101-D   110- PE */
        out = {3'b001, in};                           // FOR 32 BIT [31:0]  ,[31:30]=X, [29:28]=Y, [27:26]=Z                   
  else         
    begin
      if(in[27:26]>zn)
         out = {3'b100, in};                         
      else if(in[27:26]<zn) 
         out = {3'b101,in};   
      else
        begin
           if(in[31:30]>xn)
             out = {3'b010, in};
          else if(in[31:30]<xn) 
             out = {3'b011, in}; 
         else
              out = {3'b110, in};      
          
        end   
      
    end    
end

endmodule

module yzx #(parameter xn=2'b00, parameter yn=2'b00, parameter zn=2'b00)(northin, southin, eastin, westin, upin, downin, pein, northout, southout, eastout, westout, upout, downout, peout);

input [31:0]northin, southin, eastin, westin, upin, downin, pein;
output [34:0]northout, southout, eastout, westout, upout, downout, peout;       //ZXY ALGO WITH 7-INPUT(6BITS) 7-OUTPUT(3BITS)


singleflit #(xn, yn, zn) r0(northin, northout);
singleflit #(xn, yn, zn) r1(southin, southout);
singleflit #(xn, yn, zn) r2(eastin, eastout);                              
singleflit #(xn, yn, zn) r3(westin, westout);
singleflit #(xn, yn, zn) r4(upin, upout);
singleflit #(xn, yn, zn) r5(downin, downout);
singleflit #(xn, yn, zn) r6(pein, peout);

endmodule

module ejectarbiter (input1,input2,out);
input[34:0]input1,input2;
output reg [34:0]out;
reg in1state, in2state;

always@(*)
begin                                           
    if(input1[34:33]==2'b11)
      in1state =1'b1;
    else
     in1state =1'b0;
    
    if(input2[34:33]==2'b11)
     in2state =1'b1;
    else
     in2state =1'b0;  

  if((input1[25] ==1) && (in1state ==1)) 
     out <=input1;
  else if((input2[25] ==1) && (in2state ==1)) 
     out <=input2;
  else if( in1state ==1) 
     out <=input1;
  else if( in2state ==1) 
     out <=input2;
  else 
     out <=35'b00000000000000000000000000000000000;
end
endmodule

module kill(kill,nin,sin,ein,win,uin,din,nout,sout,eout,wout,uout,dout);      //killstage
input [34:0]nin, sin, ein, win, uin, din, kill;
output reg [34:0]nout,sout,eout,wout, uout, dout;
always@(*)
begin
 
  if (nin==kill)
  begin
     nout <=35'b00000000000000000000000000000000000;
     sout <=sin;
     eout <=ein;
     wout <=win;
     uout <=uin;
     dout <=din;
    end
  else if (sin==kill)
  begin
     nout <=nin;
     sout <=35'b00000000000000000000000000000000000;
     eout <=ein;
     wout <=win;
     uout <=uin;
     dout <=din;
    end  
  else if (ein==kill)
  begin
     nout <=nin;
     sout <=sin;
     eout <=35'b00000000000000000000000000000000000;
     uout <=uin;
     dout <=din;
    end  
  else if (win==kill)
  begin
     nout <=nin;
     sout <=sin;
     eout <=ein;
     wout <=35'b00000000000000000000000000000000000;
     uout <=uin;
     dout <=din;
    end 
    else if (uin==kill)
  begin
     nout <=nin;
     sout <=sin;
     eout <=ein;
     uout <=35'b00000000000000000000000000000000000;
     wout <=win;
     dout <=din;
    end 
    else if (din==kill)
  begin
     nout <=nin;
     sout <=sin;
     eout <=ein;
     dout <=35'b00000000000000000000000000000000000;
     uout <=uin;
     wout <=win;
    end 
   else 
   begin
     nout <=nin;
     sout <=sin;
     eout <=ein;
     wout <=win;
     uout <=uin;
     dout <=din;
     
    end 
end

endmodule

module ejector (nin,sin,ein,win,uin,din,nout,sout,eout,wout,uout,dout,eject);                //ejector
input [34:0]nin, sin, ein, win, uin, din;
output  [34:0]nout,sout,eout,wout, uout, dout;
output reg[31:0] eject;
wire [34:0]out1,out2,out3,out4,out5;

ejectarbiter  ea1(nin,ein,out1);
ejectarbiter  ea2(sin,win,out2);
ejectarbiter  ea3(uin,din,out3);
ejectarbiter  ea4(out1,out2,out4);
ejectarbiter  ea5(out4,out3,out5);
kill          k(out5,nin,sin,ein,win,uin,din,nout,sout,eout,wout,uout,dout);
always@(*)
eject=out5[31:0];

endmodule  

module injector (n_in, s_in, e_in, w_in, u_in, d_in, pein, n_out, s_out, e_out, w_out, u_out, d_out, inject_request, inject_grant);
input [34:0]n_in, s_in, e_in, w_in, pein, u_in, d_in;
input inject_request;
output reg inject_grant;
output reg [34:0]n_out,s_out,e_out,w_out, u_out, d_out;

always@(*)
begin
  if(inject_request==1)
  begin  
     if(n_in==35'b00000000000000000000000000000000000)
      begin
         n_out=pein;
         s_out=s_in;
         e_out=e_in;
         w_out=w_in;
         u_out=u_in;
         d_out=d_in;
         inject_grant=1'b1;

        end
     else if(s_in==35'b00000000000000000000000000000000000)
        begin
         s_out=pein;
         n_out=n_in;
         e_out=e_in;
         w_out=w_in;
         u_out=u_in;
         d_out=d_in;
         inject_grant=1;
        end 
     else if(e_in==35'b00000000000000000000000000000000000)
        begin
         e_out=pein;
         s_out=s_in;
         n_out=n_in;
         w_out=w_in;
         u_out=u_in;
         d_out=d_in;
         inject_grant=1;
        end 
     else if(w_in==35'b00000000000000000000000000000000000)
      begin
         w_out=pein;
         s_out=s_in;
         e_out=e_in;
         n_out=n_in;
         u_out=u_in;
         d_out=d_in;
         inject_grant=1;
        end 
      else if(u_in==35'b00000000000000000000000000000000000)
       begin
         u_out=pein;
         n_out=n_in;
         e_out=e_in;
         w_out=w_in;
         s_out=s_in;
         d_out=d_in;
         inject_grant=1;
        end 
     else if(d_in==35'b00000000000000000000000000000000000)
      begin
         d_out=pein;
         n_out=n_in;
         e_out=e_in;
         w_out=w_in;
         u_out=u_in;
         s_out=s_in;
         inject_grant=1;
        end 
     else
      begin
         n_out=n_in;
         s_out=s_in;
         e_out=e_in;
         w_out=w_in;
         u_out=u_in;
         d_out=d_in;
         inject_grant=0;
        end     
    end
 else
    begin
     n_out=n_in;
     s_out=s_in;
     e_out=e_in;
     w_out=w_in;
     u_out=u_in;
     d_out=d_in;
     inject_grant=0;
    end
end    
endmodule

module eject_inject(n_inn, s_inn, e_inn, w_inn, u_inn, d_inn, peinn, n_outt, s_outt, e_outt, w_outt, u_outt, d_outt, peoutt, inject_request, inject_grant);
input [34:0]n_inn, s_inn, e_inn, w_inn, peinn, u_inn, d_inn;
input inject_request, inject_grant;
output  [34:0]n_outt,s_outt,e_outt,w_outt, u_outt, d_outt;
output  [31:0]peoutt;
wire[34:0] w1,w2,w3,w4,w5,w6;

ejector  e1(n_inn, s_inn, e_inn, w_inn, u_inn, d_inn, w1, w2, w3, w4, w5, w6, peoutt);
injector i1(w1, w2, w3, w4, w5, w6, peinn, n_outt, s_outt, e_outt, w_outt, u_outt, d_outt, inject_request, inject_grant);
endmodule

module arbiter_stage1( in1,in2,out1,out2);      
input [34:0]in1,in2;
output reg [34:0] out1,out2;
	
    always@(in1,in2) 
    begin
	  if(in1[25]==1)
        begin
            if(in1[33]==0)
            begin  
                out1<=in1;
                out2<=in2;
            end
            else
             begin  
                out1<=in2;
                out2<=in1;
            end
        end

     else if(in2[25]==1)
        begin
            if(in2[33]==0)
            begin  
                out1<=in2;
                out2<=in1;
            end
            else
             begin  
                out1<=in1;
                out2<=in2;
            end
        end
     else if (in1[33]==1) 
        begin
         out1<=in2;
         out2<=in1;
        end
     else if (in2[33]==1) 
        begin
         out1<=in1;
         out2<=in2;
        end   
     else 
        begin
         out1<=in1;
         out2<=in2;
        end   

    end
endmodule

module arbiter_stage1x( inn1,inn2,outt1,outt2);      
input [34:0]inn1,inn2;
output reg [34:0] outt1,outt2;
	
    always@(inn1,inn2) 
    begin
	  if(inn1[25]==1)
        begin
            if((inn1[33]==0)&&(inn1[34]==0))
            begin  
                outt1<=inn1;
                outt2<=inn2;
            end
            else
             begin  
                outt1<=inn2;
                outt2<=inn1;
            end
        end

     else if(inn2[25]==1)
        begin
            if((inn2[33]==0)&&(inn2[34]==0))
            begin  
                outt1<=inn2;
                outt2<=inn1;
            end
            else
             begin  
                outt1<=inn1;
                outt2<=inn2;
            end
        end
     else if (inn1[33]==1) 
        begin
         outt1<=inn2;
         outt2<=inn1;
        end
     else if (inn2[33]==1) 
        begin
         outt1<=inn1;
         outt2<=inn2;
        end      
     else 
        begin
         outt1<=inn1;
         outt2<=inn2;
        end   

    end
endmodule

module arbiter_stage2( innn1,innn2,outtt1,outtt2);      
input [34:0]innn1,innn2;
output reg [34:0] outtt1,outtt2;
	
    always@(innn1,innn2) 
    begin
	  if(innn1[25]==1)
        begin
            if(innn1[33]==0)
            begin  
                outtt1<=innn1;
                outtt2<=innn2;
            end
            else
             begin  
                outtt1<=innn2;
                outtt2<=innn1;
            end
        end

     else if(innn2[25]==1)
        begin
            if(innn2[33]==0)
            begin  
                outtt1<=innn2;
                outtt2<=innn1;
            end
            else
             begin  
                outtt1<=innn1;
                outtt2<=innn2;
            end
        end
     else if (innn1[33]==1) 
        begin
         outtt1<=innn2;
         outtt2<=innn1;
        end
     else if (innn2[33]==1) 
        begin
         outtt1<=innn1;
         outtt2<=innn2;
        end      
     else 
        begin
         outtt1<=innn1;
         outtt2<=innn2;
        end   

    end
endmodule

module arbiter_stage2x( in1,in2,out1,out2);      
input [34:0]in1,in2;
output reg [34:0] out1,out2;
	
    always@(in1,in2) 
    begin
	  if(in1[25]==1)
        begin
            if((in1[33]==0)&&(in1[34]==0))
            begin  
                out1<=in1;
                out2<=in2;
            end
            else
             begin  
                out1<=in2;
                out2<=in1;
            end
        end

     else if(in2[25]==1)
        begin
            if((in2[33]==0)&&(in2[34]==0))
            begin  
                out1<=in2;
                out2<=in1;
            end
            else
             begin  
                out1<=in1;
                out2<=in2;
            end
        end
     else 
        begin
         out1<=in1;
         out2<=in2;
        end   

    end
endmodule

module arbiter_stage3( inn1,inn2,outt1,outt2);      
input [34:0]inn1,inn2;
output reg [34:0] outt1,outt2;
	
    always@(inn1,inn2) 
    begin
	  if(inn1[25]==1)
        begin
            if(inn1[32]==0)
            begin  
                outt1<=inn1;
                outt2<=inn2;
            end
            else
             begin  
                outt1<=inn2;
                outt2<=inn1;
            end
        end

     else if(inn2[25]==1)
        begin
            if(inn2[32]==0)
            begin  
                outt1<=inn2;
                outt2<=inn1;
            end
            else
             begin  
                outt1<=inn1;
                outt2<=inn2;
            end
        end
     else if(inn1[34]==1)
        begin
            if(inn1[32]==0)
            begin  
                outt1<=inn1;
                outt2<=inn2;
            end
            else
             begin  
                outt1<=inn2;
                outt2<=inn1;
            end
        end

     else if(inn2[34]==1)
        begin
            if(inn2[32]==0)
            begin  
                outt1<=inn2;
                outt2<=inn1;
            end
            else
             begin  
                outt1<=inn1;
                outt2<=inn2;
            end
        end   
     else 
        begin
         outt1<=inn1;
         outt2<=inn2;
        end   

    end
endmodule



module pdn (N_in ,S_in , E_in ,W_in, U_in, D_in, N_out, S_out, E_out, W_out, U_out, D_out);

input [34:0] N_in ,S_in , E_in , W_in, U_in, D_in;
output  [34:0] N_out, S_out, E_out, W_out, U_out, D_out;
wire [34:0]link1, link2, link3, link4, link5, link6, link7, link8, link9, link10, link11, link12;

arbiter_stage1 a1( N_in, E_in, link1, link2);
arbiter_stage1 a2( S_in, W_in, link3, link4);
arbiter_stage1x a3( U_in, D_in, link5, link6);

arbiter_stage2x a4( link1, link3, link7, link8);
arbiter_stage2 a5( link2, link5, link9, link10);
arbiter_stage2 a6( link4, link6, link11, link12);

arbiter_stage3 a7( link7, link9, N_out, S_out);
arbiter_stage3 a8( link8, link11, U_out, D_out);
arbiter_stage3 a9( link10, link12, E_out, W_out);


endmodule

module chipper #(parameter xn=2'b00, parameter yn=2'b00, zn=2'b00)(NORTHIN, SOUTHIN, EASTIN, WESTIN, UPIN, DOWNIN, PEIN, NORTHOUT, SOUTHOUT, EASTOUT, WESTOUT, UPOUT, DOWNOUT, PEOUT, inject_request, inject_grant); 

input[31:0]NORTHIN, EASTIN, SOUTHIN, WESTIN, PEIN, UPIN, DOWNIN;
output reg[31:0] NORTHOUT, EASTOUT, SOUTHOUT, WESTOUT, UPOUT, DOWNOUT;
output [31:0]PEOUT;
input inject_request;
output reg inject_grant;
wire[34:0] n1, s1, e1, w1, u1, d1, p1; 
wire[34:0] n3, s3, e3, w3, u3, d3;
wire[34:0] n4, s4, e4, w4, u4, d4;  

yzx #(xn, yn, zn) routing(NORTHIN, SOUTHIN, EASTIN, WESTIN, UPIN, DOWNIN, PEIN, n1, s1, e1, w1, u1, d1, p1);
eject_inject stage1(n1, s1, e1, w1, u1, d1, p1, n3, s3, e3, w3, u3, d3, PEOUT, inject_request, inject_grant);
pdn permutation_network(n3, s3, e3, w3, u3, d3, n4, s4, e4, w4, u4, d4);    

always@(*)
begin
    
    NORTHOUT <= n4[31:0];
    SOUTHOUT <= s4[31:0];
    EASTOUT  <= e4[31:0];
    WESTOUT  <= w4[31:0];
    UPOUT    <= u4[31:0];
    DOWNOUT  <= d4[31:0];
       
  
end
endmodule
