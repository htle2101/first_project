require 'sidekiq/web'

BuyChina::Application.routes.draw do
  constraints Constraints::Mobile do
    root :to => 'mobile/home#index'
  end
  resources :stores
  resources :guides, :only => [:show, :index]
  get 'guide/:slug-:id' => 'guides#sub_category', :as => :category_guide
  resources :categories, :only => [:index]
  resources :products, :only => [:index, :show] do
    collection do
      get :calculate_price, :wsprice, :store, :guides
    end
    member do
      get :skus, :detail, :ship_method, :reviews
    end
  end
  get 'stores/:id(/:slug-:cid)(/:page_no)' => "stores#show", :as => :store_category
  resources :stores
  get 'brands/:id(/:slug-:cid)(/:page_no)' => "brands#show", :as => :brand_category
  resources :brands
  get 'tag/:pid/:vid(/:slug-:cid)(/:page_no)' => "tags#show", :as => :tag_category

  #get '/sellers' => 'products#store'
  get '/items/:id' => "products#items"
  get '/search' => 'products#search', :as => :search
  get '/popular/:keyword(/:page)' => 'products#popular', :page => /\d+/, :as => :popular
  get '/popular/:slug-:cid/:keyword(/:page)' => 'products#popular', :cid => /\d+/, :page => /\d+/, :as => :popular
  get '/category/:slug-:cid(/:page)' => 'products#category_search', :as => :category_search
  get '/reviews/:id' => "reviews#add", :as => :add_one

  resource :cart, :only => [:edit, :update] do
    collection do
      put :update_line_item_quantity
      delete :delete_line_item
    end
  end

  resources :large_orders, :only => [:new, :create, :show] do
    post :send_message, :on => :member
  end

  #get "checkouts/address" => "addresses#checkout"
  post 'addresses/change_state' => 'addresses#change_state'
  resources :addresses, :path => 'checkouts/addresses'
  resources :checkouts, :only => [] do
    collection do
      get :select_category
      get :weight
      get :shipment
      get :preview
      get :order_adjustment
      get :payment
      get :buy_now
      post :update_weight
      post :update_shipment
      post :update_address
      post :place_order
      post :pay
    end
  end

  resources :payments, :only => [] do
    collection do
      #get :express, :express_complete
      post :wallet_pay
      post :wallet_pay_order_adjustment
    end
  end
  resources :favourites, :only => [] do
    collection do
      post :add
    end
  end

  resources :front_categories, :only => [] do
    collection do
      get :ajax_get_products
    end
  end

  root :to => 'home#index'
  get 'manage/front_modules_test' => "home#front_modules"

  # auto generate xxx_home_index_path and xxx_home_index_url method
  resources :home, :only => [], :path => "/" do
    collection do
      get :affiliate
      get 'affiliate_faq'
      get 'Affiliate', :to => redirect('/affiliate')
      get :update_captcha
      get :verify_captcha
      get :suggest
      get :autocomplete_keywords
    end
  end

  put "products/add_to_cart" => "products#add_to_cart", :as => :add_to_cart
  get 'category_list' => 'categories#list'
  post 'paypal/notify' => "paypal_notifies#execute"
  resources :alipay, :only => [] do
    collection do
      post :notify
      get :complete
    end
  end

  resources "webmoney", :only => [], :path => 'wm' do
    collection do
      post :notify
      post :complete
      post :fail
    end
  end
  #post 'wm/notify' => "webmoney#notify", :as => :webmoney_notify
  #post 'wm/complete' => "webmoney#complete", :as => :webmoney_complete
  #post 'wm/fail' => "webmoney#fail", :as => :webmoney_fail
  #get 'autocomplete_keywords' => 'home#autocomplete_keywords', :as => :autocomplete_keywords


  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations", :passwords => "users/passwords", :omniauth_callbacks => "users/omniauth_callbacks" }, :skip => [:registrations, :sessions]

  devise_scope :user  do
    get 'login' => 'users/sessions#new', :as => :login
    post 'login' => 'users/sessions#create', :as => :login
    get 'logout' => 'users/sessions#destroy', :as => :logout
    get 'signup' => 'users/registrations#new', :as => :signup
    post 'signup' => 'users/registrations#create', :as => :signup

    # for devise
    get 'login' => 'users/sessions#new', :as => :new_user_session
    get 'logout' => 'users/sessions#destroy', :as => :destroy_user_session
    get 'signup' => 'users/registrations#new', :as => :new_user_registration
    get 'signup/success' => 'users/registrations#success', :as => :signup_success

    get 'users/check' => 'users/registrations#check', :as => :user_check
    get 'users/sign_in/check' => 'users/sessions#check', :as => :user_sign_check

    get 'users/password/password_sent' => 'users/passwords#password_sent', :as => :password_sent
    get 'users/password/changed' => 'users/passwords#changed', :as => :changed
    get 'users/password/reset' => 'users/passwords#reset', :as => :reset_password
    put 'users/password/reset' => 'users/passwords#reset'
    get 'users/resend_confirmation' => 'users/confirmations#resend', :as => :resend_confirmation
  end

  get 'my' => 'my#index', :as => :my
  get 'my/resend_confirm' => 'my#resend_confirm'
  get "my/large_orders" => 'large_orders#index', :as => :my_large_orders
  get "my/large_orders/:id" => 'large_orders#show', :as => :my_large_order
  get 'snapshot/:id' => 'my/orders#snapshot', :as => :my_product_snapshot

  #get 'brands/:id' => 'front_categories#brands', :as => :brand
  get 'activities/:id' => 'front_categories#front_categories', :as => :front_category
  get 'promotions/:id' => 'front_categories#promotions', :as => :promotion

  resources :promotions
  #post 'deposits/notify' => "deposits_notify#execute"
  namespace :my do
    resources :addresses
    resources :affiliates, :only => [:index] do
      get :settle, :on => :collection
    end


    resources :orders, :only => [:index, :show] do
      collection do
        post :send_message
      end
      member do
        put :cancel
        #get :confirm_deliver
      end
      resource :product_feedbacks, :as => :reviews, :path => "reviews"
    end

    resources :favourites, :only => [:index] do
      delete :remove, :on => :collection
    end
    resource :account, :only => [:show, :update]
    get 'message/check' => 'messages#check_order_number', :as => :order_number_check
    resources :messages do
      collection do
        post :send_message
      end
    end
    resource :wallet do
      get :transfer, :withdraw, :history
      post :transfer, :withdraw   #, :to_paypal
    end

    resources :deposits, :only => [] do
      collection do
        get :transfer, :transfer_complete
      end
    end
  end  # end :my namespace

  #get 'my/messages' => 'my/messages#index'#, :as => :messages
  get 'my/password' => 'my/accounts#change_pwd', :as => :my_profile
  #  if Rails.env.development?
  #get '(/*prefix)/images/*suffix' => proc {|env| ['404', {'Content-Type' => 'text/plain'}, ['resource not found']]}
  #  end
  get 'user/sign' => 'home#sign', :as => :sign

  # redirct to guides and will removed
  get '/blog' => redirect('/guides')
  get '/blog/:id' => redirect('/guides')
  get '/blog/tagged/:tag_id/:tag_name' => redirect('/guides')

  get 'images/:id' => 'images#show', :as => "upload_image"

  # for common pages
  get 'help' => "pages#index"
  get '/contact' => redirect("/help")

  # redirect to new help and will removed
  get 'pages/shipping' => redirect('/help/shipping')
  get 'pages/:id' => redirect('/help')
  get 'help/shipping' => "pages#shipping"
  constraints Constraints::CommonPage do
    get 'help/:id' => 'pages#common', :as => :common_page
  end
  constraints PageType do
    get 'help/:id' => 'pages#page_type', :as => :page_type_pages
  end
  resources :pages, :path => :help do
    member do
      post :feedback
    end
  end

  get 'manage' => 'manage/home#index'
  namespace :manage do
    resources :taobaos, :only => [:index]
    get "taobaos/:purchase_product_id/detail" => "taobaos#detail", :as => :taobao_detail
    post "taobaos/purchase_on_taobao" => "taobaos#purchase_on_taobao", :as => :purchase_on_taobao
    get "taobaos/taobao_session" => "taobaos#taobao_session", :as => :taobao_session
    put "taobaos/update_taobao_session" => "taobaos#update_taobao_session", :as => :update_taobao_session
    post "taobaos/get_items" => "taobaos#get_items", :as => :taobaos_get_items
    post 'ebay_publish/:taobao_id' => "ebay_publish#publish", :as => :ebay_publish
    resources :batch_products
    post 'batch_products_start' => "batch_products#start", :as => :batch_product_start
    resources :emails do
      get 'send_email' => "emails#send_email", :as => :send_email
      get 'test_send_email' => "emails#test_send_email", :as => :test_send_email
    end
    resources :large_orders, :only => [:index, :show] do
      member do
        post :send_message
        get :mark
      end
    end
    resources :front_modules
    post "front_modules/upload" => "front_modules#upload"
    get 'front_modules_type/:type' => "front_modules#type", :as => :front_modules_type
    put 'front_modules_category/:id' => 'front_modules#toggle_category'
    put 'front_modules_locale/:id' => 'front_modules#toggle_locale'
    resources :product_feedbacks
    resources :photos, :only => [:create, :destroy]

    resources :pages, :except => :show do
      collection do
        post :create_type
        get :announcement
        get :common
      end
    end
    resources :page_types, :except => :show do
      member do
        get :children
      end
    end
    resources :upload_images, :only => [:new, :create]

    resources :guides do
      collection do
        get :category_children
        get :category_index
        get :add_product
        post :review
      end
    end
    resources :order_adjustments
    resources :taobaoke_products
    resources :products, :only => [:index, :edit, :update] do
      collection do
        post 'index' => 'products#index'
        get :reimport
        post :edit_promotion
        get :edit_pv_name
        post :update_pv_name
      end
      member do
        delete :off_sale
        put :on_sale
        put :expire_cache
      end
    end

    resources :orders , :only => [:index, :show, :update] do
      get :reviews, :pay, :on => :collection
      member do
        get :deliver, :refund, :payment, :shipping, :change, :new_task
        post :deliver, :refund, :send_message, :claim, :create_task
        put :shipping
      end
    end

    resources :tasks, :only => [] do
      member do
        get :assign
        post :do_assign
        put :complete
        get :add_comment
        post :do_comment
      end
    end

    resources :messages do
      member do
        get :mark
        post :send_message
      end
    end

    resources :purchase_products, :only => [:edit, :update]
    resources :categories, :only => [:index, :edit, :update] do
      collection do
        get :edit
        get :search_by_name
      end
      member do
        get :parents
        get :children
      end
    end

    resources :users, :only => [:index, :show, :update] do
      member do
        get :orders
        post :change_roles
        put :change_fund
      end
      collection do
        get :roles
      end
    end

    resources :affiliates, :only => [:index] do
      collection do
        get :referrals
        get :details
        get :orders
        get :rebates
      end

      member do
        get :product
      end
    end

    resources :search_keys do
      get :shields, :on => :collection
    end
    resources :user_search_keys
    resources :keywords do
      collection do
        get :brands, :translated, :autocomplete
      end
    end
    resources :front_categories do
      collection do
        get 'new_second/:id' => 'front_categories#new_second', :as => :new_second
        get :check_slug
        #get ':type' => 'front_categories#index', :type => /[brands|topics]/, :as => 'other'
      end
      member do
        get :edit_seo
      end
    end
    resources :promotions do
      member do
        get :edit_seo
      end
    end
    resources :topics do
      collection do
        get :add_products
        get :manage_products
        post :manage_products
        post :upload
      end
      member do
        get :edit_seo
      end
    end
    delete "/manage/topics/destroy_product/:id" => "topics#destroy_product", :as => :destroy_product
    resources :brands
    resources :tags do
      collection do
        post :edit_pv_status
      end
    end
    resources :deposits

    resources :crawls, :only => [:index, :new, :edit, :update, :destroy] do
      collection do
        post :create
      end
    end
    resources :ship_methods do
      collection do
        get :change_status
      end
    end
    resources :countries do
      collection do
        get :ship_method
        get :search_by_name
        get :new_izone
      end
    end

    resources :charts, :only => :index

  end

  #constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.admin? }
  constraints Constraints::Sidekiq do
    mount Sidekiq::Web => '/jobs'
  end

  get 'categories/:slug-:cid(/:page_no)' => "products#index", :as => :category_products
  tps = lambda { |request| FrontCategory.topics.find(request.params[:slug]) rescue false }
  constraints tps do
    get '/:slug(/:id(/:topic))' => "front_categories#topics", :as => :topic
  end

  path = lambda do |params, request|
    page_no = "/#{params[:page_no]}" if params[:page_no]
    "http://#{request.host_with_port}/categories/#{URI.encode(params[:slug])}-#{params[:cid]}#{page_no}"
  end
  match ':slug-:cid(/:page_no)', :to => redirect(path)

  match "/404", :to => "home#not_found", :as => :not_found
  match "/500", :to => "home#error"
end
