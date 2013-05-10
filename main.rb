# encoding: UTF-8

require 'sinatra'
require "data_mapper" #ORM para acesso ao banco de dados
require 'digest/md5'
require_relative 'pony_gmail'
require 'dropbox-api'
require 'sinatra/flash'

 #require 'gosu'


enable :sessions

configure do
  # setting one option
	if development?
		set :server, 'webrick'
	end
end

APP_SECRET = "simone"
path=File.expand_path(File.dirname(__FILE__))
path2='sqlite://'+path.to_s+'/entdb.db'
$log=[]
MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\.b|webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|mobile'

if development?
	DataMapper.setup(:default, path2)
	else
#DataMapper.setup(:default, 'sqlite://test.db')
	DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
end

Dropbox::API::Config.app_key    = "5iab174blvc0r2a"
Dropbox::API::Config.app_secret = "anjx0jpxnun1aya"
Dropbox::API::Config.mode       = "dropbox"
@@client = Dropbox::API::Client.new(:token  => "obln21lls8mqlns", :secret => "w19fp981vkr5fie")
helpers do
  def hesc(text)
    Rack::Utils.escape_html(text)
  end
  
  def  login?
    if session[:username].nil?
      #flash[:error]="Sessão expirada! Favor entrar novamente."
      return false
    else
	    #puts "true"
      return true
    end
  end
  
  def username
    return session[:username]
  end
  
  def admin?
    if session[:admin].nil?
      #flash[:error]="Sessão expirada! Favor entrar novamente."
      return false
    else
	    #puts "true"
      return true
    end
  end
  
	def geracodigo(pedido)
		logger.info "geracodigo"
		pedido.update(:cadtime=>Time.now.localtime("-03:00"))
		pedido.update(:cod=>pedido.cadtime.strftime("%Y%m%d%H%M%S").to_s+("%05d" % pedido.id).to_s)
		logger.info pedido.cod
	end
  
end


######Classe Usuário############################################
#layout da classe para autenticação e autorização de usuários###
################################################################
class Usuario
	include DataMapper::Resource

	property :id, Serial
	property :nome, String, :required => true
	property :senha, String, :required =>true
	property :sexo, String, :required=>true
	property :cpf, String, :required=>true
	property :ddd, String, :required=>true
	property :fone, String, :required=>true
	property :ramal, String
	property :cep, String, :required=>true
	property :cidade, String, :required=>true
	property :estado, String, :required=>true
	property :endereco, String, :required=>true
	property :numero, String, :required=>true
	property :complemento, String
	property :tipores, String
	property :prediocasa, String
	property :edificio, String
	property :apartamento, String
	property :andar, String
	property :bloco, String
	property :condominio, String
	property :torre, String
	property :conjunto, String
	property :loja, String
	property :lote, String
	property :quadra, String
	property :sala, String
	property :referencia, String, :required=>true
	property :empresa, String
	property :nascimento, String
	property :email, String, :required => true, :format => :email_address, :unique => true
	property :news, String
	property :cadtime, Text
	property :adm, Boolean, :default=>false
	property :mst, Boolean, :default=>false
	property :cepmst, String
	
	has n, :bandeijas
	
	def getcepmst
		ccep=Usuario.first(:adm=>true, :cepmst=>self.cep)
		if ccep==nil
			self.update(:cepmst=>Cepmst.first(:id=>1).cep)
			else
			self.update(:cepmst=>self.cep)
		end
	end	
end

class Cepmst
	include DataMapper::Resource

	property :id, Serial
	property :cep, String
end

class Tipo
	include DataMapper::Resource

	property :id, Serial
	property :nome, String, :required => true
	
	has n, :marmitas
end


class Marmita
	include DataMapper::Resource

	property :id, Serial
	property :nome, String, :required => true
	property :desc, Text
	property :preco, Float
	property :img, Text
	property :pers, Boolean, :default=>false
	property :prov, Boolean, :default=>false
	
	has n, :componentes
	has 1, :princicomp
	has n, :itembandeijas
	belongs_to :tipo
end

class Ingrediente
	include DataMapper::Resource

	property :id, Serial
	property :nome, String, :required => true
	
	has n, :componentes
end

class Componente
	include DataMapper::Resource

	property :id, Serial
	
	belongs_to :ingrediente
	belongs_to :marmita
end

class Principal
	include DataMapper::Resource

	property :id, Serial
	property :nome, String, :required => true
	
	has n, :princicomps
end

class Princicomp
	include DataMapper::Resource

	property :id, Serial
	
	belongs_to :principal
	belongs_to :marmita
end

class Itembandeija
	include DataMapper::Resource

	property :id, Serial
	property :qtd, Integer
	property :val, Float
	
	belongs_to :marmita
	belongs_to :bandeija
end

class Bandeija
	include DataMapper::Resource

	property :id, Serial
	property :confirmed, Boolean, :default=>false
	property :ackn, Boolean, :default=>false
	property :enviado, Boolean, :default=>false
	property :delivered, Boolean, :default=>false
	property :forma, String
	property :deltime, DateTime
	property :prepronto, Boolean, :default=>false
	property :cadtime, DateTime, :default=>Time.now.localtime("-03:00")
	property :cod, String
	property :coment, Text
	
	belongs_to :usuario
	has n, :itembandeijas
	
	def sum
		s=0.0
		self.itembandeijas.all.each do |item|
			s+=item.val
		end
		s
	end
	
	def status
		a=""
		if self.confirmed==true
			a="Aguardando"
		end
		if self.ackn==true
			a="Confirmado"
		end
		if self.enviado==true
			a="Enviado"
		end
		if self.delivered==true
			a="Entregue"
		end
		a
	end
	
	def today
		if self.cadtime.strftime("%m/%d/%Y")==Time.now.localtime("-03:00").strftime("%m/%d/%Y")
			a=true
			else
			a=false
		end
		a
	end

	
end

class Taxa
	include DataMapper::Resource

	property :id, Serial
	property :val, Float
end

class Horario
	include DataMapper::Resource
	
	property :id, Serial
	property :nome, String
	property :inicio, DateTime
	property :fim, DateTime
	
end
##
class Slide
	include DataMapper::Resource
	
	property :id, Serial
	property :img, Text
	property :texto, String
end

class Campanha
	include DataMapper::Resource
	
	property :id, Serial
	property :imgg, Text
end

class Email
	include DataMapper::Resource
	
	property :id, Serial
	property :smtp, String
	property :port, Integer
	property :login, String
	property :senha, String
	property :domain, String
	
end

DataMapper.finalize
#Usuario.auto_migrate!
#Cepmst.auto_migrate!
#Campanha.auto_migrate!
#Email.auto_migrate!
#DataMapper.auto_migrate!
#Bandeija.auto_migrate!
#Marmita.auto_migrate!
#Itembandeija.auto_migrate!
#Princicomp.auto_migrate!
#Componente.auto_migrate!
#Tipo.auto_migrate!

before do
	meses=["", "Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
	dias=["Domingo","Segunda-Feira","Terça-Feira","Quarta-Feira","Quinta-Feira","Sexta-Feira","Sábado"]
	m=Time.now.strftime("%-m").to_i
	d=Time.now.strftime("%w").to_i
	@data=Time.now.strftime("#{dias[d]}, %d de #{meses[m]} de %Y")
	if login?
		@user=Usuario.first(:email => username)
		if request.path_info!="/" and request.path_info!="/logout" and not admin?
		if d==0
			hh=Horario.first(:nome=>"Domingo")
			else
			if d==6
				hh=Horario.first(:nome=>"Sabado")
				else
				hh=Horario.first(:nome=>"Semana")
			end
		end
		if Time.now.localtime("-03:00").strftime("%H").to_i<hh.inicio.strftime("%H").to_i or Time.now.localtime("-03:00").strftime("%H").to_i>hh.fim.strftime("%H").to_i
			
				logger.info request.path_info
				flash.next[:error]='Infelizmente, nossa loja não está funcionando nesse momento. Confira nosso <a href="/funcionamento">horário de funcionamento.</a>'
				redirect to("/logout")
		end
		end
	end
	@stt=""
end


get '/' do
	@stt=' onload="runSlideShow();"'
	erb :index
end

post '/envcad' do
	logger.info params
	if Usuario.first(:email=>params[:p_email])!=nil
		flash.next[:error]="Email já cadastrado."
		redirect to("/")
	end
	mail=Email.first(:id=>1)
	cadtime=Time.now.localtime("-03:00")
	senha=Digest::MD5.hexdigest(cadtime.to_s + APP_SECRET + params[:p_senha2])
	@senha=params[:p_senha2]
	@nome=params[:p_nome]
	if nuser=Usuario.create(:nome=>params[:p_nome], :sexo=>params[:p_sexo], :cpf=>params[:p_cpf], :ddd=>params[:p_ddd], :fone=>params[:p_telefone], :ramal=>params[:p_ramal], :cep=>params[:p_cep], :cidade=>params[:p_cidade], :estado=>params[:p_uf], :endereco=>params[:p_logr_com_tipo], :numero=>params[:p_num], :complemento=>params[:p_complemento], :referencia=>params[:p_referencia], :empresa=>params[:p_empresa], :nascimento=>params[:p_data_nascimento], :email=>params[:p_email], :senha=>senha, :news=>params[:p_formador_opiniao], :cadtime=>cadtime.to_s)
		logger.info "!!!"
		nuser.getcepmst
		if nuser.id!=nil and nuser.id>0
		if Pony.mail(:to=>params[:p_email], 
		:from => mail.login, 
		:subject=> "Bem vindo ao Entrega Web",
		:headers => { 'Content-Type' => 'text/html' },
		:body => erb(:mail, :layout=>false),
		:via => :smtp, :smtp => {
		:host       => mail.smtp,
		:port       => mail.port.to_s,
		:user       => mail.login,
		:password   => mail.senha,
		:auth       => :plain,
		:domain     => mail.domain
		}
		)
			
		end
		end
	end
	@senha=nil
	@nome=nil
	redirect to("/endcadframe")
end

post "/login" do
	if params[:senha]==nil or params[:email_login]==nil
		flash.next[:error]="E-mail e/ou senha incorretos."
		redirect to ('/cadastrar')
	end
	usu=Usuario.first(:email=>params[:email_login])
	if usu==nil
		flash.next[:error]="E-mail e/ou senha incorretos."
		redirect to ('/cadastrar')
		else
			if Digest::MD5.hexdigest(usu.cadtime.to_s + APP_SECRET + params[:senha])==usu.senha
			session[:username]=params[:email_login]
			if usu.adm==true
				session[:admin]="true"
			end
			
			flash[:success]="Login efetuado com sucesso!"
			redirect to('/oferta')
			else
				flash.next[:error]="E-mail e/ou senha incorretos."
				redirect to("/cadastrar")
		end
	end
end

post "/recsenha" do
	if params[:email_login]==nil
		flash.next[:error]="E-mail e/ou senha incorretos."
		redirect to ('/recuperasenha')
	end
	usu=Usuario.first(:email=>params[:email_login])
	if usu==nil
		flash.next[:error]="E-mail e/ou senha incorretos."
		redirect to ('/recuperasenha')
		else 
			mail=Email.first(:id=>1)
			@senhatemp =  Time.now.strftime('%H%M%S').to_s
			senhatemp = @senhatemp
			if a=usu.update(:senha=>Digest::MD5.hexdigest(usu.cadtime.to_s + APP_SECRET + senhatemp))
	        		if Pony.mail(:to=>"testentrega@gmail.com", 
		                 :from => mail.login, 
	                         :subject=> "Rest. Jeito Pra Coisa - Reset de Senha",
		                 :headers => { 'Content-Type' => 'text/html' },
		                 :body => erb(:recsenha_mail, :layout=>false),
		                 :via => :smtp, :smtp => {
		                    :host       => mail.smtp,
		                    :port       => mail.port.to_s,
		                    :user       => mail.login,
		                    :password   => mail.senha,
		                    :auth       => :plain,
		                    :domain     => mail.domain
		                   })
				   flash.next[:success]="Senha resetada e enviada com sucesso!"
		                   redirect to('/')  
		          end
			else
			 flash.next[:error]="Erro na recuperação de senha!"	
			 redirect to('/recuperasenha')  
		end
	end
end


get "/logout" do
	#window = Gosu::Window.new(640, 480, false)
	#@tune = Gosu::Sample.new(window, "public/wine_glass.wav")
    	#@tune.play
	session[:username] = nil
	session[:admin] = nil
	redirect to('/')
end

get '/top' do
	logger.info "### #{username}"
	meses=["", "Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
	dias=["Domingo","Segunda-Feira","Terça-Feira","Quarta-Feira","Quinta-Feira","Sexta-Feira","Sábado"]
	m=Time.now.strftime("%-m").to_i
	d=Time.now.strftime("%w").to_i
	@data=Time.now.strftime("#{dias[d]}, %d de #{meses[m]} de %Y")
	if login?
		@user=Usuario.first(:email => username)
	end
	
	erb :top, :layout=>false
end

get '/side' do
	erb :side, :layout=>false
end

get '/recuperasenha' do
	erb :recuperasenha
end

get '/oferta' do
	if not login?
		redirect to("/cadastrar")
	end
	redirect to("/oferta/t/1")
end

get '/oferta/t/:id' do |id|
	if not login?
		redirect to("/")
	end
	@id=id
	erb :oferta
end


get '/oferta/t/:id2/:id' do |id2, id|
	if not login?
		redirect to("/")
	end
	if id=="0"
		redirect to('/oferta')
	end
	@id2=id2
	@id=id
	erb :ofertam
end

get '/funcionamento' do
	erb :funcionamento
end

get '/telefones' do
	erb :telefones
end

get '/cadastrar' do
	erb :cadastrar
end

get '/editauser/:id' do |id|
	@id=id.to_i
	erb :euser
end

post '/envpostcad/:id' do |id|
	logger.info params
	usu=Usuario.first(:id=>id.to_i)
	if b=usu.update(:nome=>params[:p_nome], :sexo=>params[:p_sexo], :cpf=>params[:p_cpf], :ddd=>params[:p_ddd], :fone=>params[:p_telefone], :ramal=>params[:p_ramal], :cep=>params[:p_cep], :cidade=>params[:p_cidade], :estado=>params[:p_uf], :endereco=>params[:p_logr_com_tipo], :numero=>params[:p_num], :complemento=>params[:p_complemento], :referencia=>params[:p_referencia], :empresa=>params[:p_empresa], :nascimento=>params[:p_data_nascimento], :email=>params[:p_email], :news=>params[:p_formador_opiniao])
		if params[:cepmst]!=nil
			b=usu.update(:cepmst=>params[:cepmst])
		end
		flash.next[:success]="Cadastro atualizado com sucesso!"
		else
			flash.next[:error]="Cadastro não pode ser atualizado."
	end
	redirect to ("/verusuarios")
end


get '/cadastro' do
	erb :cadastro
end

post '/envaltcad' do
	logger.info params
	usu=Usuario.first(:email=>username)
	if params[:p_senha2]!="" and params[:p_senha3]!="" and params[:p_senha2at]!=""
		if usu.senha != Digest::MD5.hexdigest(usu.cadtime.to_s + APP_SECRET + params[:p_senha2at])
			flash.next[:error]="Senha incorreta."
			logger.info "senha incorreta"
			redirect to "/cadastro"
		end
	
		if params[:p_senha2]!=params[:p_senha3]
			flash.next[:error]="Confirmação de nova senha não confere."
			redirect to "/cadastro"
		end
	
		if a=usu.update(:senha=>Digest::MD5.hexdigest(usu.cadtime.to_s + APP_SECRET + params[:p_senha2]))
			flash.next[:success]="Senha atualizada com sucesso!"
		end
	end
	logger.info usu
	if b=usu.update(:nome=>params[:p_nome], :sexo=>params[:p_sexo], :cpf=>params[:p_cpf], :ddd=>params[:p_ddd], :fone=>params[:p_telefone], :ramal=>params[:p_ramal], :cep=>params[:p_cep], :cidade=>params[:p_cidade], :estado=>params[:p_uf], :endereco=>params[:p_logr_com_tipo], :numero=>params[:p_num], :complemento=>params[:p_complemento], :referencia=>params[:p_referencia], :empresa=>params[:p_empresa], :nascimento=>params[:p_data_nascimento], :email=>params[:p_email], :news=>params[:p_formador_opiniao])
		flash.next[:success]="Cadastro atualizado com sucesso!"
		else
			flash.next[:error]="Cadastro não pode ser atualizado."
	end
	redirect to ("/cadastro")
end

get '/cadframe' do
	erb :cadframe, :layout=>false
end

get '/cadframe2' do
	erb :cadframe2, :layout=>false
end

get '/cadframe1' do
	erb :cadframe1, :layout=>false
end

get '/cadhead' do
	erb :cadhead, :layout=>false
end

get '/cadcont' do
	erb :cadcont, :layout=>false
end

get '/cadcont2' do
	erb :cadcont2, :layout=>false
end

get '/cadform' do
	erb :cadform
end

get '/endcadframe' do
	erb :endcadframe
end

get '/tabelanutricional' do
	erb :nut
end

get '/nutframe' do
	erb :nutframe, :layout=>false
end

get '/nuthead' do
	erb :nuthead, :layout=>false
end

get '/nutcont' do
	erb :nutcont, :layout=>false
end

get '/cadprod' do
	erb :cadprod
end

get '/cadprodframe' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/oferta")
	end
	erb :cadprodframe
end

get '/cadprodhead' do
	erb :cadprodhead, :layout=>false
end

get '/cadprodform' do
	erb :cadprodform, :layout=>false
end

post '/envcadprod' do
	if params[:tipo]=="0"
		if params[:ntipo]!=""
			tipo=Tipo.create(:nome=>params[:ntipo])
			else
			flash[:error]="Escolha o tipo de produto"
			redirect to('/cadprodframe')
		end
		else
		tipo=Tipo.first(:id=>params[:tipo].to_i)
	end
	logger.info params
	if newcad=Marmita.create(:nome=>params[:cad_nome].to_s, :preco=>params[:cad_preco].to_f, :desc=>params[:cad_desc])
		tipo.marmitas<<newcad
		newcad.save
		pp=Principal.first(:id=>params[:principal].to_i)
		princip=Princicomp.create
		acomp=[]
		for i in 0..15 do
			if params["i#{i}"]!="0"
				a=Componente.create
				b=Ingrediente.first(:nome=>params["i#{i}"])
				b.componentes<<a
				acomp<<a
			end
		end
		newcad.princicomp= princip
		pp.princicomps<<princip
		princip.save
		acomp.each do |aa|
			newcad.componentes<<aa
			aa.save
		end
		
	
	redirect to("/cadimage/#{newcad.id}")
	end
end

get '/altprodframe' do
	erb :altprodframe
end

get '/editamarmita/:id' do |id|
	@mmid=id
	erb :editamarmita
end

post '/envaltprod/:id' do |id|
	marm=Marmita.first(:id=>id.to_i)
	nome=params[:cad_nome]
	preco=params[:cad_preco].to_f
	desc=params[:cad_desc]
	pp=Principal.first(:id=>params[:principal].to_i)
	marm.update(:nome=>nome, :preco=>preco, :desc=>desc)
	marm.princicomp.destroy!
	marm.componentes.each do |p|
		p.destroy!
	end
	princip=Princicomp.create
	acomp=[]
	for i in 0..15 do
		if params["i#{i}"]!="0"
			a=Componente.create
			b=Ingrediente.first(:nome=>params["i#{i}"])
			b.componentes<<a
			acomp<<a
		end
	end
	marm.princicomp= princip
	pp.princicomps<<princip
	princip.save
	acomp.each do |aa|
		marm.componentes<<aa
		aa.save
	end
	redirect to("/editamarmita/#{id}")
end

get '/apagamarmita/:id' do |id|
	marm=Marmita.first(:id=>id.to_i)
	marm.princicomp.destroy!
	marm.componentes.each do |comp|
		comp.destroy!
	end
	marm.destroy!
	redirect to("/altprodframe")
end

	

post '/envcustprod' do
	logger.info params
	if newcad=Marmita.create(:nome=>params[:cad_nome].to_s+(Marmita.last.id+1).to_s+"ct"+Usuario.first(:email=>username).id.to_s, :preco=>params[:cad_preco].to_f, :img=>params[:img], :pers=>true)
		pp=Principal.first(:id=>params[:principal].to_i)
		princip=Princicomp.create
		acomp=[]
		for i in 0..params[:c2].to_i-1 do
			if params["i#{i}"]!="0"
				n=params["i#{i}"].to_s
				a=Componente.create
				logger.info params["i#{i}"]
				b=Ingrediente.first(:nome=>n)
				logger.info b
				b.componentes<<a
				acomp<<a
			end
		end
		newcad.princicomp= princip
		pp.princicomps<<princip
		princip.save
		acomp.each do |aa|
			newcad.componentes<<aa
			aa.save
		end
		
		user=Usuario.first(:email=>username)
		if Bandeija.first(:usuario_id=>user.id, :confirmed=>false, :prepronto=>false)==nil
			band=Bandeija.create(:usuario_id=>user.id)
			else
				band=Bandeija.first(:usuario_id=>user.id)
		end
		item=Itembandeija.create(:qtd=>params["qtd"].to_i, :val=>(params["qtd"].to_i)*newcad.preco)
		band.itembandeijas<<item
		newcad.itembandeijas<<item
		item.save
	redirect to("/oferta")
	end
end

get "/cadimage/:id" do |id|
	logger.info id
	session[:marmid]=id.to_s
	logger.info session[:marmid]
	erb :cadimage
end

post "/1" do
	tmpfile = params[:file][:tempfile]
        name = params[:file][:filename]
	a=@@client.upload "public/fcs/img/"+name, tmpfile
	logger.info "######"+params[:marmid]
	b=Marmita.first(:id=>params[:marmid].to_i)
	logger.info b.id.to_s
	logger.info a.direct_url.url.to_s
	b.update(:img=>"https://dl.dropbox.com/u/166141160/fcs/img/"+name)
	redirect to("/oferta")
end

get '/caditem' do
	erb :caditem
end

get '/caditemframe' do
	if not login?
		redirect to("/center")
	end
	if not admin?
		redirect to("/oferta")
	end
	erb :caditemframe
end

post '/envcaditem' do
	for i in 0..3 do
		if params["cad_nome#{i}"]!=""
			if params["tipo#{i}"]=="0"
				Principal.create(:nome=>params["cad_nome#{i}"].to_s)
				else
				if params["tipo#{i}"]=="1"
					Ingrediente.create(:nome=>params["cad_nome#{i}"].to_s)
				end
			end
		end
	end
	redirect to("/cadready")
end

get "/cadready" do
	erb :cadready
end

post "/envofform" do
	logger.info params
	parstr=""
	params.each do |par|
		if par[0][0..2]=="add"
			parstr=par[0].split(".")[0]
			else
			if par[0][0..2]=="dif"
				parstr=par[0].split(".")[0]
			end
		end
	end
	if parstr[0..2]=="add"
		logger.info "YES!"
		user=Usuario.first(:email=>username)
		marm=Marmita.first(:id=>parstr[3].to_i)
		if Bandeija.first(:usuario_id=>user.id, :confirmed=>false, :prepronto=>false)==nil
			band=Bandeija.create(:usuario_id=>user.id)
			else
				band=Bandeija.first(:usuario_id=>user.id, :confirmed=>false, :prepronto=>false)
		end
		item=Itembandeija.create(:qtd=>params["qtd#{parstr[3]}"].to_i, :val=>(params["qtd#{parstr[3]}"].to_i)*marm.preco)
		band.itembandeijas<<item
		marm.itembandeijas<<item
		item.save
		else
		if parstr[0..2]=="dif"
			redirect to("/customiza/#{parstr[3]}")
		end
	end
	
	redirect to("/oferta")
	
end

get '/customiza/:id' do |id|
	@id=id
	erb :custom
end

get '/customframe/:id' do |id|
	@id=id
	erb :customframe, :layout=>false
end

get '/user' do
	erb :user, :layout=>false
end

post '/retiraitem/:id' do |id|
	item=Itembandeija.first(:id=>id.to_i)
	band=item.bandeija
	item.destroy
	if band.itembandeijas.all.size==0
		band.destroy
	end
	redirect to("/oferta")
end

get '/cancelabandeija' do
	if not login?
		redirect to("/")
	end
	logger.info "####"
	logger.info Usuario.first(:email=>username).email
	Bandeija.all(:usuario_id=>Usuario.first(:email=>username).id, :confirmed=>false, :prepronto=>false).each do |band|
		logger.info band.id
		band.itembandeijas.each do |item|
			item.destroy
		end
		band.destroy
	end
	Bandeija.all(:usuario_id=>Usuario.first(:email=>username).id, :confirmed=>false, :prepronto=>false).each do |band|
		band.destroy
	end
	redirect to("/oferta")
end

get '/finalizabandeija' do
	if not login?
		redirect to("/")
	end
	redirect to("/finaliza")
end

get '/finaliza' do
	erb :finaliza
end

post '/confdin' do
	@pedido=Bandeija.first(:usuario_id=>Usuario.first(:email=>username).id, :confirmed=>false, :prepronto=>false)
	if @pedido!=nil
		@pedido.update(:confirmed=>true, :forma=>"Dinheiro", :coment=>params[:coment])
		geracodigo(@pedido)
		mail=Email.first(:id=>1)
		if Pony.mail(:to=>mail.login, 
			:from => mail.login, 
			:subject=> "Pedido #{@pedido.cod}",
			:headers => { 'Content-Type' => 'text/html' },
			:body => erb(:c_mail, :layout=>false),
			:via => :smtp, :smtp => {
			:host       => mail.smtp,
			:port       => mail.port.to_s,
			:user       => mail.login,
			:password   => mail.senha,
			:auth       => :plain,
			:domain     => mail.domain
			}
		)
		end
	end
	
	erb :aprov
end

get '/dinheiro' do
	erb :dinheiro
end

	
get '/cartao' do
	erb :cartao
end

get '/finframe' do
	erb :finframe, :layout=>false
end

get '/finhead' do
	erb :finhead, :layout=>false
end

get '/fincont' do
	erb :fincont, :layout=>false
end

post '/finaction' do
	logger.info params
	params
end


get '/finaction' do
	logger.info params
	#if params["aprovar"]!=nil
		redirect to ('/pedidoaprovado')
	#	else
	#	if params["reprovar"]!=nil
	#		redirect to ("/pedidonaoaprovado")
	#	end
	#end
	erb :aprov
end

get "/pedidoaprovado" do
	@pedido=Bandeija.first(:usuario_id=>Usuario.first(:email=>username).id, :confirmed=>false, :prepronto=>false)
	if @pedido!=nil
		@pedido.update(:confirmed=>true, :forma=>"Cartão")
		geracodigo(@pedido)
		mail=Email.first(:id=>1)
		if Pony.mail(:to=>mail.login, 
			:from => mail.login, 
			:subject=> "Pedido #{@pedido.cod}",
			:headers => { 'Content-Type' => 'text/html' },
			:body => erb(:c_mail, :layout=>false),
			:via => :smtp, :smtp => {
			:host       => mail.smtp,
			:port       => mail.port.to_s,
			:user       => mail.login,
			:password   => mail.senha,
			:auth       => :plain,
			:domain     => mail.domain
			}
		)
		end
	end
	erb :aprov
end

get "/aprframe" do
	erb :aprframe, :layout=>false
end

get "/aprcont" do
	erb :aprcont, :layout=>false
end

get "/pedidonaoaprovado" do
	erb :reprov
end

get "/repframe" do
	erb :repframe, :layout=>false
end

get "/repcont" do
	erb :repcont, :layout=>false
end

post "/repaction" do
	if params[:choice]=="Tentar novamente"
		redirect to ('/finaliza')
		else
		if params[:choice]=="Cancelar Pedido"
			redirect to ("/cancelabandeija")
		end
	end
end

get "/precadastra" do
	if not login?
		redirect to("/")
	end
	band=Bandeija.first(:usuario_id=>Usuario.first(:email=>username).id)
	band.update(:prepronto=>true)
	redirect to('/favoritos')
end

get "/includepre/:id" do |id|
	band=Bandeija.first(:id=>id)
	user=Usuario.first(:email=>username)
	its=[]
	band2=Bandeija.first(:usuario_id=>user.id, :confirmed=>false, :prepronto=>false)
	if band2==nil
		band2=Bandeija.create(:usuario_id=>user.id)
	end
	band.itembandeijas.each do |it|
		its<<Itembandeija.create(:qtd=>it.qtd, :val=>it.val, :marmita_id=>it.marmita.id, :bandeija_id=>band2.id)
	end
	redirect to("/oferta")
end

get "/excludepre/:id" do |id|
	if not login?
		redirect to("/")
	end
	band=Bandeija.first(:usuario_id=>Usuario.first(:email=>username).id)
	band.update(:prepronto=>false)
	redirect to('/favoritos')
end

get "/favoritos" do
	if not login?
		redirect to("/")
	end
	erb :favoritos
end

get "/favframe" do
	erb :favframe, :layout=>false
end

get '/altitemframe' do
	if not login?
		flash[:error]="Você não tem autorização para utilizar essa opção."
		redirect to("/")
	end
	if not admin?
		flash[:error]="Você não tem autorização para utilizar essa opção."
		redirect to("/")
	end
	erb :altitemframe
end

post '/envaltitem' do
	Principal.all.each do |item|
		item.update(:nome=>params["princ_nome#{item.id}"])
	end
	Ingrediente.all.each do |item|
		item.update(:nome=>params["acomp_nome#{item.id}"])
	end
	redirect to("/altitemframe")
end

get '/apagaprinc/:id' do |id|
	ittem=Principal.first(:id=>id.to_i)
	logger.info ittem.nome
	a=Princicomp.all(:principal_id=>id.to_i)
	marm=[]
	a.each do |aa|
		marm<<a.marmita
	end
	a=nil
	
	logger.info "rrr -"+Princicomp.all(:principal_id=>id.to_i).destroy.to_s
	logger.info "ppp - "+ittem.destroy.to_s
	
	marm.each do |mm|
	mm.componentes.each do |item|
		logger.info "iii - "+item.destroy.to_s
	end
	end
	marm.each do |item|
	logger.info "mmm - "+item.destroy!.to_s
	end
	redirect to("/altitemframe")
end

get '/apagacomp/:id' do |id|
	ittem=Ingrediente.first(:id=>id.to_i)
	logger.info ittem.nome
	a=Componente.all(:ingrediente_id=>id.to_i)
	
	logger.info "rrr -"+Componente.all(:ingrediente_id=>id.to_i).destroy.to_s
	logger.info "ppp - "+ittem.destroy.to_s
	
	redirect to("/altitemframe")
end

get '/acompanhamento' do
	if not login?
		redirect to("/")
	end
	erb :acompanhamento
end

get '/acompframe' do
	erb :acompframe, :layout=>false
end

get '/acompcont' do
	erb :acompcont, :layout=>false
end

get '/pedidos' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :pedidos
end

get '/confped/:id' do |id|
	a=Bandeija.first(:id=>id.to_i)
	a.update(:ackn=>true)
	redirect to ("/pedidos")
end

get '/entped/:id' do |id|
	a=Bandeija.first(:id=>id.to_i)
	a.update(:ackn=>true, :enviado=>true, :delivered=>true)
	redirect to ("/pedidos")
end

get '/envped/:id' do |id|
	a=Bandeija.first(:id=>id.to_i)
	a.update(:ackn=>true, :enviado=>true)
	redirect to ("/pedidos")
end

get '/pedido/:id' do |id|
	@id=id
	erb :pedido
end

get '/alttaxa' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :alttaxa
end

post '/ntaxa' do
	tax=Taxa.first(:id=>1)
	if tax!=nil
		tax.update(:val=>params[:val].to_f)
		else
		tax=Taxa.create(:val=>params[:val].to_f)
	end
	redirect to("/alttaxa")
end

get "/verusuarios" do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :vuser
end


get '/lojafisica' do
	erb :lojafisica, :layout=>false
end

get '/diskquentinhas' do
	erb :disquentinhas, :layout=>false
end

get '/rodape' do
	erb :rodape
end

get '/download' do
	erb:download
end

get '/javacad' do
	erb :javacad
end

get '/javaindex' do
	erb :javaindex
end

get '/config' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :config
end

get '/config2' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :config2
end

get "/alteraslide/:id" do |id|
	@id=id
	erb :alteraslide
end

post "/altslide" do
	tmpfile = params[:file][:tempfile]
        name = params[:file][:filename]
	a=@@client.upload "public/fcs/img/slides/"+name, tmpfile
	id=params[:id].to_i
	slide=Slide.first(:id=>id)
	slide.update(:img=>"https://dl.dropbox.com/u/166141160/fcs/img/slides/"+name, :texto=>params[:nome])
	flash[:success]="Slide #{id} alterado com sucesso!"
	redirect to("/config")
end

get "/alteralogo/:id" do |id|
	@id=id
	erb :alteralogo
end

post "/altlogo" do
	tmpfile = params[:file][:tempfile]
        name = params[:file][:filename]
	a=@@client.upload "public/fcs/img/main/"+name, tmpfile
	id=params[:id].to_i
	logo=Campanha.first(:id=>id)
	logo.update(:imgg=>"https://dl.dropbox.com/u/166141160/fcs/img/main/"+name)
	flash[:success]="Logo #{id} alterado com sucesso!"
	redirect to("/config")
end

post "/subconfig" do
	params.each do |par|
		logger.info par
		logger.info par[0]
		logger.info par[1]
		logger.info "step1"
		if par[0][0..5]=="button"
			semini=Time.now.localtime("-03:00").to_s
			semini[11..12]=("%02d" % params[:semin1].to_i).to_s
			semini[14..15]="%02d" % params[:semin2].to_i
			logger.info semini
			semend=Time.now.localtime("-03:00").to_s
			semend[11..12]="%02d" % params[:semout1].to_i
			semend[14..15]="%02d" % params[:semout2].to_i
			Horario.first(:nome=>"Semana").update(:inicio=>semini, :fim=>semend)
			sabini=Time.now.localtime("-03:00").to_s
			sabini[11..12]="%02d" % params[:sabin1].to_i
			sabini[14..15]="%02d" % params[:sabin2].to_i
			sabend=Time.now.localtime("-03:00").to_s
			sabend[11..12]="%02d" % params[:sabout1].to_i
			sabend[14..15]="%02d" % params[:sabout2].to_i
			Horario.first(:nome=>"Sabado").update(:inicio=>sabini, :fim=>sabend)
			domini=Time.now.localtime("-03:00").to_s
			domini[11..12]="%02d" % params[:domin1].to_i
			domini[14..15]="%02d" % params[:domin2].to_i
			domend=Time.now.localtime("-03:00").to_s
			domend[11..12]="%02d" % params[:domout1].to_i
			domend[14..15]="%02d" % params[:domout2].to_i
			Horario.first(:nome=>"Domingo").update(:inicio=>domini, :fim=>domend)
			flash[:success]="Horários alterados com sucesso!"
			redirect to("/config")
			else
				logger.info "step2"
			if par[0][0..5]=="b_mail"
				logger.info "####"
				mail=Email.first(:id=>1)
				logger.info "!!!!"
				if mail.update(:domain=>params[:domain], :smtp=>params[:smtp], :senha=>params[:senha], :port=>params[:port].to_i, :login=>params[:login])==true
					logger.info "$$$$"
					flash[:success]="Dados de email alterados com sucesso!"
					redirect to("/config")
					else
					flash[:error]="Não foi possível alterar os parâmetros de email. Favor confirir os dados."
					redirect to("/config")
				end
			else
				logger.info "step3"
			if par[0][0..4]=="b_pag"
				logger.info "####"
				pag=Email.first(:id=>2)
				if pag.update(:login=>params[:pag])==true
					logger.info "$$$$"
					flash[:success]="Dados do pagseguro alterados com sucesso!"
					redirect to("/config")
					else
					flash[:error]="Não foi possível alterar os parâmetros do pagseguro. Favor confirir os dados."
					redirect to("/config")
				end
			else
				logger.info "step4"
			if par[0]=="b_taxa"
				logger.info "&&&&&&&&&&"
				tax=Taxa.first(:id=>1)
				if tax!=nil
					tax.update(:val=>params[:val].to_f)
					flash[:success]="Taxa alterada com sucesso."
					redirect to("/config")
					else
					tax=Taxa.create(:val=>params[:val].to_f)
					flash[:success]="Taxa criada com sucesso."
					redirect to("/config")
				end
			else
			if par[0]=="b_cep"
				cep=Cepmst.first(:id=>1)
				if a=cep.update(:cep=>params[:cep])
					flash[:success]="CEPMST alterado com sucesso."
					else
					flash[:error]="CEPMST não pode ser alterado."
				end
			end
			end
			end
			end
			
		end
	end
end

get '/quemsomos' do
	erb :quem
end

get '/politica' do
	erb :politica
end

get '/termo' do
	erb :termo
end

get '/faleconosco' do
	erb :fale
end

get '/duvidascomuns' do
	erb :duvidas
end

post '/smail' do
	mail=Email.first(:id=>1)
	@mail=[params[:nome], params[:tel], params[:mail], params[:msg]]
	if Pony.mail(:to=>mail.login, 
            :from => mail.login,
            :subject=> "Email recebido pelo site em #{Time.now.localtime("-03:00").strftime('%d/%m/%y - %H:%M')}",
	    :headers => { 'Content-Type' => 'text/html' },
            :body => erb(:mail1, :layout=>false),
            :via => :smtp, :smtp => {
              :host       => mail.smtp,
              :port       => mail.port,
              :user       => mail.login,
              :password   => mail.senha,
              :auth       => :plain,
              :domain     => mail.domain
             }
           )
	   
	if Pony.mail(:to=>params[:mail].to_s, 
            :from => mail.login, 
            :subject=> "Contato JeitoWeb",
	    :headers => { 'Content-Type' => 'text/html' },
            :body => erb(:mail2, :layout=>false),
            :via => :smtp, :smtp => {
              :host       => mail.smtp,
              :port       => mail.port,
              :user       => mail.login,
              :password   => mail.senha,
              :auth       => :plain,
              :domain     => mail.domain
             }
           )
	flash[:success]="Mensagem enviada com sucesso!"
	end
	end
	redirect to "/faleconosco"
end

get '/makeadm/:id' do |id|
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	usu=Usuario.first(:id=>id.to_i)
	usu.update(:adm=>true)
	redirect to('/verusuarios')
end

get '/makeusu/:id' do |id|
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	usu=Usuario.first(:id=>id.to_i)
	usu.update(:adm=>false)
	redirect to('/verusuarios')
end

get '/config3' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :config3
end

get '/config4' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :config4
end

get '/config5' do
	if not login?
		redirect to("/")
	end
	if not admin?
		redirect to("/")
	end
	erb :config5
end