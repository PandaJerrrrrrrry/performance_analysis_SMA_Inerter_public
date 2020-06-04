function  [Omega, Sx, Sigma_X, Sigma_XP, Sxp, Sigma_XA, Sxa]=stochastic_response(lamda1, Phi1, r)
%****************************************************************
%----             Author(s): Wang Chao, Jia Yingqi           ----
%----             Affiliation: Tongji University             ----
%----             E-mail: jiayingqi@tongji.edu.cn            ----
%----             Date: 10/22/2020                           ----
%****************************************************************

omg1=0.001*2.0*pi; % ������ʼ��ֵ
omg2=50.0*2.0*pi; % ������ֹ��ֵ
n=12000; % ���ֵ����
Omega = linspace(omg1, omg2, n+1);
N=length(lamda1)/2; % ���ɶȸ����������������ɶȣ�
Sg=0.1; % m^2/s^3

%% ��Z����
Z=ones(n+1,1)*r';
Z=Z'./(Omega*sqrt(-1)-lamda1);

% ʹ��Kanai-Tajimi����ģ�ͣ�������˸�˹������ģ�ͣ�
omg_g=9*pi; % �������������Ƶ�ʣ�rad/s
xi_g=0.6; % ������������������
Sg=Sg*(omg_g^4+4*xi_g^2*omg_g^2.*Omega.^2)./((omg_g^2-Omega.^2).^2+4*xi_g^2*omg_g^2.*Omega.^2);

Y=Phi1*Z.*sqrt(Sg);
dY=Omega*sqrt(-1).*Y;

%% ������
X=Y(N+1:2*N,:); % ȡY���°벿�֣�λ�ƴ��ݺ�����
XP=Y(1:N,:); % ȡY���ϰ벿�֣��ٶȴ��ݺ�����
XA=dY(1:N,:); % ȡY���ϰ벿�֣����ٶȴ��ݺ�����
XP1=dY(N+1:2*N,:); % ȡY���ϰ벿�֣����ٶȴ��ݺ�����

Sx=conj(X).*X; % λ������
Sxp=conj(XP).*XP; % �ٶ�����
Sxa=conj(XA).*XA; % ���ٶ�����

% ����һ�������׵ķ���
% Sxp=Omega.^2.*Sx; % �ٶ�����
% Sxa=Omega.^4.*Sx; % ���ٶ�����

%% ����Ӧ�ı�׼��
dOmega=Omega(2:n+1)-Omega(1:n);
Sum1=ones(N,1)*dOmega.*Sx(:,2:n+1);
Sigma_X=sqrt(sum(Sum1,2)); %sum(x,2)��ʾ��x�����ÿһ�зֱ���ͣ�������������
Sum2=ones(N,1)*dOmega.*Sxp(:,2:n+1);
Sigma_XP=sqrt(sum(Sum2,2));
Sum3=ones(N,1)*dOmega.*Sxa(:,2:n+1);
Sigma_XA=sqrt(sum(Sum3,2));