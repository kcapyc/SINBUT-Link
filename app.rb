require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

# админка 1/1
configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Вход с паролем'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Вам необходимо войти для доступа к ' + request.path
    halt erb(:login_form)
  end
end
# админка 1/1

def is_category_exists? db, name
	db.execute('select * from Categorys where name=?', [name]).size > 0
end

def seed_db db, categorys

	categorys.each do |category|
		if !is_category_exists? db, category
			db.execute 'insert into Categorys (name) values (?)', [category]
		end 
	end

end

def get_db
	db = SQLite3::Database.new 'list.db'
	db.results_as_hash = true
	return db
end

before do
	db = get_db
	@categorys = db.execute 'select * from Categorys'
end

configure do
	db = get_db
	db.execute 'CREATE TABLE IF NOT EXISTS
		"Users"
		(
			"id" INTEGER PRIMARY KEY AUTOINCREMENT,
			"guestname" TEXT,
			"phone" TEXT,
			"datestamp" TEXT,
			"category" TEXT,
			"message" TEXT
		)'

	db.execute 'CREATE TABLE IF NOT EXISTS
		"Categorys"
		(
			"id" INTEGER PRIMARY KEY AUTOINCREMENT,
			"name" TEXT
		)'

	seed_db db, ['Option one', 'Option two', 'Option three', 'Option four']
end

get '/' do
  erb 'Здесь будет информация для главной страницы.'
end

# админка 2/2
get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
	@username = params[:username]
	@pass = params[:pass]

	if @pass == 'love'
		  session[:identity] = params['username']
		  where_user_came_from = session[:previous_url] || '/'
		  redirect to where_user_came_from
	else
		@error = 'Доступ запрещен'
		return erb :login_form
	end

end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Вы вышли</div>"
end

get '/secure/place' do
	db = get_db

	@results = db.execute 'select * from Users'
#	лист в обратном порядке:
#	@results = db.execute 'select * from Users order by id desc'

	erb :list
end
# админка 2/2

get '/about' do
	erb :about
end

get '/contacts' do
	erb :contacts
end

get '/visit' do
	erb :visit
end

post '/visit' do

	@guestname = params[:guestname]
	@phone = params[:phone]
	@datetime = params[:datetime]
	@category = params[:category]
	@message = params[:message]

	# хеш
	hh = { 	:guestname => 'указать имя',
			:phone => 'указать телефон',
			:datetime => 'указать дату и время',
			:message => 'написать сообщение' }

	@error = hh.select {|key,_| params[key] == ""}.values.join(", ")

	if @error != ''
		@error.insert(0, 'Вы забыли ')
		return erb :visit
	end

	db = get_db
	db.execute 'insert into
		Users
		(
			guestname,
			phone,
			datestamp,
			category,
			message
		)
		values (?, ?, ?, ?, ?)', [@guestname, @phone, @datetime, @category, @message]

	erb "<h3>Благодарим вас, #{@guestname}. Ваше письмо отправлено!</h3>"

end

get '/list' do
	db = get_db

	@results = db.execute 'select * from Users'
#	лист в обратном порядке:
#	@results = db.execute 'select * from Users order by id desc'

	erb :list
end
