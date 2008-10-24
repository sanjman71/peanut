require 'test/test_helper'

class CompaniesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:companies)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_company
    assert_difference('Company.count') do
      post :create, :company => { :name => "New Company" }
    end

    assert_redirected_to company_path(assigns(:company))
  end

  def test_should_show_company
    get :show, :id => companies(:company1).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => companies(:company1).id
    assert_response :success
  end

  def test_should_update_company
    put :update, :id => companies(:company1).id, :company => { }
    assert_redirected_to company_path(assigns(:company))
  end

  def test_should_destroy_company
    assert_difference('Company.count', -1) do
      delete :destroy, :id => companies(:company1).id
    end

    assert_redirected_to companies_path
  end
end
