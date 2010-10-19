require 'test_helper'

class LogoTest < ActiveSupport::TestCase
  
  # should have_attached_file :image
  # should_validate_attachment_presence :image
  # should_validate_attachment_content_type :image, :valid => [
  #   'image/jpeg',
  #   'image/pjpeg', # for progressive Jpeg ( IE mine-type for regular Jpeg ) 
  #   'image/png',
  #   'image/x-png', # IE mine-type for PNG
  #   'image/gif'
  #   ],
  #   :invalid => [
  #     'application/pdf',
  #     'application/msword',
  #     'image/bmp',
  #     'image/tiff',
  #     'image/svg+xml',
  #     'image/x-icon'
  #   ]
  # should_validate_attachment_size :image, :less_than => 1024*1024

  def setup
    @logo     = Logo.new
    @image1   = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "Kunst-Eichel.jpg"), 'rb')
    @image2   = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "rose.jpg"), 'rb')
    @pdf      = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "walnut_places.pdf"), 'rb')
    @bigimage = File.new(File.join(File.dirname(__FILE__), "..", "fixtures", "crude_awakening.jpg"), 'rb')
  end
  
  # Make sure we can add a logo to a company
  fast_context "add a logo image" do
    setup do
      @logo.image = @image1
      assert @logo.save
      @image1path = @logo.image.path
    end
    
    teardown { @logo.destroy unless @logo.nil? }
    
    should "create its thumbnails properly" do
      assert_match /\b800x[0-9]+\b/, `identify "#{@logo.image.path(:original)}"`
      assert_match /\b100x[0-9]+\b/, `identify "#{@logo.image.path(:large)}"`
      assert_match /\b50x[0-9]+\b/, `identify "#{@logo.image.path(:medium)}"`
      assert_match /\b25x[0-9]+\b/, `identify "#{@logo.image.path(:small)}"`
    end
    
    # Ensure there are urls for each of the logo styles
    should "have urls for each thumbnail" do
      assert_not_nil @logo.image.url
      assert_not_nil @logo.image.url(:large)
      assert_not_nil @logo.image.url(:medium)
      assert_not_nil @logo.image.url(:small)
    end
    
    # Ensure it's stored in the right place
    should "store in /public/system/:attachment/:id/:style/:filename" do
      assert File.exists?(@image1path)
    end

    # Ensure we can delete a logo
    # The image file is stored at /public/system/:attachment/:id/:style/:filename
    fast_context "then delete the image" do
      setup do
        @logo.destroy
        @logo = nil
      end
      
      should "have no thumbnails etc. any more" do
        assert !File.exists?(@image1path)
      end
      
    end

    # Ensure we can update / change a logo
    fast_context "then update the image" do
      setup do
        @logo.image = @image2
        assert @logo.save
        @image2path = @logo.image.path
      end
      
      should "create its thumbnails properly" do
        assert_match /\b800x[0-9]+\b/, `identify "#{@logo.image.path(:original)}"`
        assert_match /\b100x[0-9]+\b/, `identify "#{@logo.image.path(:large)}"`
        assert_match /\b50x[0-9]+\b/, `identify "#{@logo.image.path(:medium)}"`
        assert_match /\b25x[0-9]+\b/, `identify "#{@logo.image.path(:small)}"`
      end

      # Ensure there are urls for each of the logo styles
      should "have urls for each thumbnail" do
        assert_not_nil @logo.image.url
        assert_not_nil @logo.image.url(:large)
        assert_not_nil @logo.image.url(:medium)
        assert_not_nil @logo.image.url(:small)
      end

      # Ensure it's stored in the right place
      should "store new image in filesystem" do
        assert File.exists?(@image2path)
      end

      # Ensure the original image is no longer there
      should "not store the original image any more" do
        assert !File.exists?(@image1path)
      end
    end
  end
  
  should "not allow pdf file" do
    @logo.image = @pdf
    assert @logo.invalid?
    @logo.errors.on(:image_content_type)
  end

  should "not allow large image > 1M" do
    @logo.image = @bigimage
    assert @logo.invalid?
  end

end
