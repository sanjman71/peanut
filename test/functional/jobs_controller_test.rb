require 'test/test_helper'

class JobsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:jobs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_job
    assert_difference('Job.count') do
      post :create, :job => { :name => "Men's Haircut", :duration => 30 }
    end

    assert_redirected_to job_path(assigns(:job))
  end

  def test_should_show_job
    get :show, :id => jobs(:available).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => jobs(:available).id
    assert_response :success
  end

  def test_should_update_job
    put :update, :id => jobs(:available).id, :job => { }
    assert_redirected_to job_path(assigns(:job))
  end

  def test_should_destroy_job
    assert_difference('Job.count', -1) do
      delete :destroy, :id => jobs(:available).id
    end

    assert_redirected_to jobs_path
  end
end
