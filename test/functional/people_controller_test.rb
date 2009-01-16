require 'test/test_helper'
require 'test/factories'

class PeopleControllerTest < ActionController::TestCase

  def setup
    stub_subdomain
  end

  context "create person" do
    
    context "with an empty person" do
      setup do
        xhr :post, :create, :person => {:name => ""}
      end

      should_respond_with :success
      should_render_template 'people/create.js.rjs'
      should_respond_with_content_type "text/javascript"
      should_assign_to :person, :error_text
      should_assign_to :error, :equals => "true"
      should_not_change "Person.count"
            
      should "return error text" do
        assert_equal "Could not create person", assigns(:error_text)
      end
    end
    
    context "with a valid person" do
      setup do
        xhr :post, :create, :person => {:name => "Wilma"}
      end

      should_respond_with :success
      should_render_template 'people/create.js.rjs'
      should_assign_to :person
      should_not_assign_to :error, :error_text
      should_set_the_flash_to /Created Wilma/i
      should_change "Person.count", :by => 1
      
      should "be a rjs redirect to people index" do
        assert_equal people_path, assigns(:redirect_path)
        assert_match /window.location.href/, @response.body
        assert_match /#{people_path}/, @response.body
      end
    end
  end
  
  context "search an empty people database" do
    
    context "with an empty search" do 
      setup do
        get :index
      end

      should_respond_with :success
      should_render_template 'people/index.html.haml'
      should_not_set_the_flash
      should_assign_to :people, :search_text
      should_not_assign_to :search
    
      should "not find any people" do
        assert_equal [], assigns(:people)
      end
      
      should "have search text" do
        assert_equal "No People", assigns(:search_text)
      end
    end
    
    context "with a search for barney" do
      setup do 
        get :index, :search => 'barney'
      end

      should_respond_with :success
      should_render_template 'people/index.html.haml'
      should_not_set_the_flash
      should_assign_to :people, :search_text, :search
      
      should "find 0 people" do
        assert_equal [], assigns(:people)
      end
      
      should "have a search value" do
        assert_equal 'barney', assigns(:search)
      end

      should "have search text" do
        assert_equal "People matching 'barney'", assigns(:search_text)
      end
    end
    
  end
  
  context "search a non-empty people database" do 
    setup do
      # create company person
      @barney = Factory(:person, :name => 'Barney', :companies => [@company])
    end
    
    context "with a search for 'ba'" do
      setup do
        get :index, :search => 'ba'
      end
      
      should_respond_with :success
      should_render_template 'people/index.html.haml'
      should_respond_with_content_type "text/html"
      should_not_set_the_flash
      should_assign_to :people, :search_text, :search

      should "find barney" do
        assert_equal [@barney], assigns(:people)
      end
      
      should "have a search value" do
        assert_equal 'ba', assigns(:search)
      end

      should "have search text" do
        assert_equal "People matching 'ba'", assigns(:search_text)
      end
    end
    
    context "with a search for 'xyz'" do
      setup do
        get :index, :search => 'xyz'
      end
      
      should_respond_with :success
      should_render_template 'people/index.html.haml'
      should_respond_with_content_type "text/html"
      should_not_set_the_flash
      should_assign_to :people, :search_text, :search

      should "find 0 people" do
        assert_equal [], assigns(:people)
      end
      
      should "have a search value" do
        assert_equal 'xyz', assigns(:search)
      end

      should "have search text" do
        assert_equal "People matching 'xyz'", assigns(:search_text)
      end
    end
    
    context "with an ajax request for 'ba'" do
      setup do
        xhr :get, :index, :format => 'js', :search => 'ba'
      end

      should_respond_with :success
      should_render_template 'people/index.js.rjs'
      should_respond_with_content_type "text/javascript"
    end
    
  end
  
end