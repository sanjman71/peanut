require 'test/test_helper'

class AppointmentsControllerTest < ActionController::TestCase
  fixtures :companies, :jobs, :resources
  
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:appointments)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_appointment
    assert_difference('Appointment.count') do
      post :create, :appointment => {
                          "customer_attributes"=>{"name"=>"Customer 1", "phone"=>"6503876818", "email"=>"customer1@getfave.com"}
                      }
    end

    assert_redirected_to appointment_path(assigns(:appointment))
  end

  def test_should_show_appointment
    get :show, :id => appointments(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => appointments(:one).id
    assert_response :success
  end

  def test_should_update_appointment
    put :update, :id => appointments(:one).id, :appointment => { }
    assert_redirected_to appointment_path(assigns(:appointment))
  end

  def test_should_destroy_appointment
    assert_difference('Appointment.count', -1) do
      delete :destroy, :id => appointments(:one).id
    end

    assert_redirected_to appointments_path
  end
end
