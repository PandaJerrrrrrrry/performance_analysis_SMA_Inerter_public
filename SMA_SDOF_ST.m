function [ ]=SMA_SDOF_ST()
%% ��������Ƶ���ʱ��Ƕȷֱ����SMA-Inerter����Ӧ
%****************************************************************
%----             Author(s): Wang Chao, Jia Yingqi           ----
%----             Affiliation: Tongji University             ----
%----             E-mail: jiayingqi@tongji.edu.cn            ----
%----             Date: 10/22/2020                           ----
%****************************************************************

clear
clc

%% ����ṹ��Ϣ
m=20e3; % ԭ�ṹ������kg
Tp=0.54; % s
omega=2*pi/Tp; % ԭ�ṹƵ�ʣ�rad/s
k=m*omega^2; % ԭ�ṹ�նȣ�N/m
ksi=0.02; % ԭ�ṹ�����
c=2*ksi*omega*m; %ԭ�ṹ����ϵ����N��s/m

mu=0.08; % ���ʱ�
kpas=0.16; % SMA element��ԭ�ṹ�ն�֮��
kpad=0.08; % ����֧�ŵ�����ԭ�ṹ�ն�֮��

xd1=0.005; % m
xd2=0.02; % m
ks=kpas*k; % SMA�ĳ�ʼ�ն� N/m
alpha=0.001; % SMA�����������ǰ�ĸնȱ�

%% �޿ؽṹ
[M,C,K,E]=matrix_shear_building(m, c, k);
[lamda, Phi, r]=complex_modes(M,C,K,E);
[Omega, Sx1, Sigma_X1, Sigma_XP1, Sxp1, Sigma_XA1, Sxa1]=stochastic_response(lamda, Phi, r);

%% SMA���ƵĽṹ��ST1��
ke=100;
ce=50;
gap_k=ke;
gap_c=ce;
error=10^(-6);
% �������ke,ce��ֱ�����㾫��
while rms(gap_k)>error & rms(gap_c)>error
    temp_k=ke;
    temp_c=ce;
    kd_=alpha.*ks+(1-alpha).*ks.*ke;
    cd_=(1-alpha).*ks.*ce;
    [lamda, Phi, r] = complex_modes(m,c+cd_,k+kd_,1);
    [Omega, Sx2, Sigma_X2, Sigma_XP2, Sxp2, Sigma_XA2, Sxa2] = stochastic_response(lamda, Phi, r);
    ke=(xd2+xd1)./sqrt(2*pi)./Sigma_X2.*exp(1).^(-xd1.^2./2./Sigma_X2.^2);
    ce=(xd2-xd1)./sqrt(2*pi)./Sigma_XP2.*(1-erf(xd1/sqrt(2)./Sigma_X2));
    gap_k=ke-temp_k;
    gap_c=ce-temp_c;
end

%% SDI���ƵĽṹ(������SMA�Ȳ�����������ͨ���ɴ���)��ST2��
kd=kpad*k;
ke=10;
ce=50;
gap_k=ke;
gap_c=ce;
error=10^(-6);
% �������ke,ce��ֱ�����㾫��
item=1;
while rms(gap_k)>error & rms(gap_c)>error & item<30
    temp_k=ke;
    temp_c=ce;
    kd_=alpha.*ks+(1-alpha).*ks.*ke;
    cd_=(1-alpha).*ks.*ce;
    M=[m 0;0 mu*m];
    C=[c 0;0 cd_];
    K=[k+kd -kd;-kd kd_+kd];
    E=[1 0]';
    [lamda, Phi, r] = complex_modes(M,C,K,E);
    [Omega, Sx3, Sigma_X3, Sigma_XP3, Sxp3, Sigma_XA3, Sxa3] = stochastic_response(lamda, Phi, r);
    Sigma_XSMA3=Sigma_X3(2);
    Sigma_XPSMA3=Sigma_XP3(2);
    ke=(xd2+xd1)./sqrt(2*pi)./Sigma_XSMA3.*exp(1).^(-xd1.^2./2./Sigma_XSMA3.^2);
    ce=(xd2-xd1)./sqrt(2*pi)./Sigma_XPSMA3.*(1-erf(xd1/sqrt(2)./Sigma_XSMA3));
    gap_k=ke-temp_k;
    gap_c=ce-temp_c;
    item=item+1;
end

%% �����
% λ����Ӧ����
Sigma_X1
Sigma_X2
Sigma_X3

% ��������
ed_SMA=(1-alpha)*ks*...
    (xd2-xd1)/sqrt(2*pi)*(1-erf(xd1/sqrt(2)/Sigma_XSMA3))*Sigma_XPSMA3
ed_ST=c*Sigma_XP3(1)^2
etotal=ed_SMA+ed_ST;

disp('λ�Ƽ����')
sprintf('ST1    :%.4f',Sigma_X2(1)/Sigma_X1)
sprintf('ST2    :%.4f',Sigma_X3(1)/Sigma_X1)
disp('���ٶȼ����')
sprintf('ST1    :%.4f',Sigma_XA2(1)/Sigma_XA1)
sprintf('ST2    :%.4f',Sigma_XA3(1)/Sigma_XA1)
disp('�������˱�')
sprintf('ST     :%.4f',1-ed_SMA/etotal)

%% ��ȡ����
file1=textread('..\��������\GM1-TH.txt', '' ,'headerlines',1);
file2=textread('..\��������\GM2-TH.txt', '' , 'headerlines',1);
file3=textread('..\��������\GM3-TH.txt', '' , 'headerlines',1);
file4=textread('..\��������\Artificial_EQSignal-TH.txt', '' , 'headerlines',1);

% ����������洢��Ԫ��������ľ�����
amp=9.8; % m/s^2
wave{1}=file1(:,2)*amp;
wave{2}=file2(:,2)*amp;
wave{3}=file3(:,2)*amp;
wave{4}=file4(:,2)*amp;
dt=0.005; % ʱ����

for i=1:4
    wave{i}=wave{i}'; %��ת��
    wave{i}=wave{i}(:); %��Ϊһ��
    wave{i}=wave{i}';
    n(i)=length(wave{i});
end

%% Newmark���λ��ʱ����Ӧ
for i=1:4
    [u1{i},du1{i},ddu1{i}] = Newmark_belta(wave{i},dt,n(i),m, c, k,1);
    [u2{i},du2{i},ddu2{i}] = Newmark_belta(wave{i},dt,n(i),m,c+cd_,k+kd_,1);
    [u3{i},du3{i},ddu3{i}] = Newmark_belta(wave{i},dt,n(i),M,C,K,[1,0]');
    t{i}=linspace(0.005,n(i)*0.005,n(i));
end

%% ��ͼ
disp('����ȫ����ɣ���ʼ��ͼ')
blue=[55 126 184]/256;
orange=[255 160 65]/256;
green=[44 160 44]/256;
pink=[255 91 78]/256;
purple=[184 135 195]/256;
gray=[164 160 155]/256;

close all
% PSDF
% figure(1)
% semilogy(Omega/2/pi,[Sx1(1,:);Sx2(1,:);Sx3(1,:)],'linewidth',4)
% set(title('PSDF of displacement'),'Fontname', 'Times New Roman','FontSize',15)
% set(xlabel('Frequency (Hz)'),'Fontname', 'Times New Roman','FontSize',15)
% set(ylabel('PSDF'),'Fontname', 'Times New Roman','FontSize',15)
% set(legend('Original structure','SMA damper','SMA-Inerter'),'Fontname', 'Times New Roman','FontSize',15)
% set(gca,'Fontname', 'Times New Roman','FontSize',15)
% set(gcf,'position',[200,200,800,500])
% axis([0,2,10e-7,10e-2])
% set(gca,'looseInset',[0 0 0 0])
% grid on
% print('.\���Ĳ�ͼ\Disp PSDF','-djpeg','-r200');
%
%
% λ��ʱ������
for i=1:4
    figure('position',[100,100,600,400])
    plot(t{i},u1{i}(1,:)*1e2,'linewidth',2,'color',blue)
    hold on
    plot(t{i},u2{i}(1,:)*1e2,'linewidth',2,'color',orange)
    plot(t{i},u3{i}(1,:)*1e2,'linewidth',2,'color',green)
    hold off
    if i==1
        ylim([-5,5])
        set(gca,'ytick',-5:2:5)
        set(gca,'yticklabel',sprintf('%.1f\n',get(gca,'ytick')))
    elseif i==2
        ylim([-2.5,2.5])
        set(gca,'ytick',-2.5:1:2.5)
        set(gca,'yticklabel',sprintf('%.1f\n',get(gca,'ytick')))
        xlim([0,25])
    elseif i==3
        ylim([-15,15])
        xlim([0,20])
        set(gca,'ytick',-15:5:15)
        set(gca,'yticklabel',sprintf('%.0f\n',get(gca,'ytick')))
    else
        ylim([-20,20])
        set(gca,'ytick',-20:5:20)
        set(gca,'yticklabel',sprintf('%.0f\n',get(gca,'ytick')))
    end
    set(xlabel('Time \it t \rm (s)'),'Fontname', 'Times New Roman','FontSize',15)
%     set(ylabel('Displacement (cm)'),'Fontname', 'Times New Roman','FontSize',15)
    set(ylabel('$$  \rm Displacement \; \it u_p \; \rm (cm) $$ ','interpreter','latex'),'Fontname', 'Times New Roman','FontSize',15)
    set(legend('Original structure','With conventional SMA damper','With SDI'),'Fontname', 'Times New Roman','FontSize',15,'EdgeColor',gray,'linewidth',1.5)
    set(gca,'Fontname', 'Times New Roman','FontSize',15,'linewidth',2)
    set(gca,'looseInset',[0 0 0 0],'linewidth',2,'Fontname','Times New Roman','FontSize',15)
    grid
    set(gca,'GridLineStyle', ':','GridColor','k')
%     print(['.\���Ĳ�ͼ\Disp time history for GM ',num2str(i)],'-djpeg','-r300');
end
%
% ���ٶ�
% for i=1:4
%     figure('position',[100,100,600,400])
%     plot(t{i},ddu1{i}(1,:),'linewidth',2,'color',blue)
%     hold on
%     plot(t{i},ddu2{i}(1,:),'linewidth',2,'color',orange)
%     plot(t{i},ddu3{i}(1,:),'linewidth',2,'color',green)
%     hold off
%     if i==1
%         ylim([-7.5,7.5])
%         set(gca,'ytick',-7.5:2.5:7.5)
%         set(gca,'yticklabel',sprintf('%.1f\n',get(gca,'ytick')))
%     elseif i==2
%         ylim([-3,3])
%         xlim([0,25])
%         set(gca,'ytick',-3:1:3)
%         set(gca,'yticklabel',sprintf('%.1f\n',get(gca,'ytick')))
%     elseif i==3
%         ylim([-20,20])
%         xlim([0,20])
%         set(gca,'ytick',-20:5:20)
%         set(gca,'yticklabel',sprintf('%.0f\n',get(gca,'ytick')))
%     else
%         ylim([-28,28])
%         set(gca,'ytick',-28:7:28)
%         set(gca,'yticklabel',sprintf('%.0f\n',get(gca,'ytick')))
%     end
%     set(xlabel('Time \it t \rm (s)'),'Fontname', 'Times New Roman','FontSize',15)
%     %     set(ylabel('Acceleration (m/s^2)'),'Fontname', 'Times New Roman','FontSize',15)
%     set(ylabel('$$  \rm Acceleration \; \it \ddot u_p \; \rm (m/s^2) $$ ','interpreter','latex'),'Fontname', 'Times New Roman','FontSize',15)
%     set(legend('Original structure','With conventional SMA damper','With SDI'),'Fontname', 'Times New Roman','FontSize',15,'EdgeColor',gray,'linewidth',1.5)
%     set(gca,'Fontname', 'Times New Roman','FontSize',15,'linewidth',2)
%     set(gca,'looseInset',[0 0 0 0],'linewidth',2,'Fontname','Times New Roman','FontSize',15)
%     grid
%     set(gca,'GridLineStyle', ':','GridColor','k')
%     print(['.\���Ĳ�ͼ\Acc time history for GM ',num2str(i)],'-djpeg','-r300');
% end