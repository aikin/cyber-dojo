require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mock_disk_file'

class KataTests < ActionController::TestCase
  
  def language
    'Ruby-installed-and-working'  
  end

  def setup
    @mock_file = MockDiskFile.new
    Thread.current[:file] = @mock_file
  end
  
  def teardown
    Thread.current[:file] = nil
    system("rm -rf #{root_dir}/katas/*")
    system("rm -rf #{root_dir}/zips/*")    
  end
  
  test "created is loaded from manifest" do
    @mock_file.setup(
      [ { :created => [ 2013,6,27,18,38,42] }.inspect ]
    )
    id = 'ABCDE12345'
    kata = Kata.new(root_dir, id)
    assert kata.created.to_s.start_with?("2013-06-27 18:38:42")
  end
  
  test "age in seconds is loaded from manifest" do
    @mock_file.setup(
      [ { :created => [ 2013,6,27,18,38,42] }.inspect ]
    )
    id = 'ABCDE12345'
    kata = Kata.new(root_dir, id)
    now = Time.mktime(2013,6,27,18,39,43)
    assert_equal 61, kata.age_in_seconds(now)
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  test "multiple avatars in a kata are all seen" do
    teardown
    kata = make_kata(language)
    Avatar.new(kata, 'lion')
    Avatar.new(kata, 'hippo')
    avatars = kata.avatars
    assert_equal 2, avatars.length
    assert_equal ['hippo','lion'], avatars.collect{|avatar| avatar.name}.sort
  end
  
  test "create new named kata creates manifest with required properies" do
    teardown    
    id = 'ABCDABCD34'
    now = [2012,3,3,10,6,12]
    info = make_info(language, 'Yahtzee', id, now)
    Kata.create_new(root_dir, info)
    kata = Kata.new(root_dir, info[:id])
    
    assert_equal root_dir + '/katas/AB/CDABCD34', kata.dir
    assert File.directory?(kata.dir), "File.directory?(#{kata.dir})"
        
    manifest_rb = kata.dir + '/manifest.rb'
    assert File.exists?(manifest_rb), "File.exists?(#{manifest_rb})"
    manifest = eval(IO.read(manifest_rb))
    assert manifest.has_key?(:visible_files),
          "manifest.has_key?(:visible_files)"
    
    assert_equal manifest[:visible_files], kata.language.visible_files
    assert_equal 'Yahtzee', kata.exercise.name
    assert_equal language, kata.language.name
    assert_equal id, kata.id
    assert_equal Time.mktime(*now), kata.created
    assert_equal 'ruby_test_unit', kata.language.unit_test_framework
    assert_equal " " * 2, kata.language.tab
    seconds = 5
    now = now[0...-1] + [now.last + seconds ]
    assert_equal seconds, kata.age_in_seconds(Time.mktime(*now))
  end
  
  test "Kata.exists? returns false before kata is created and true after kata is created" do
    teardown    
    id = 'AABBCCDDEE'
    info = make_info(language, 'Yahtzee', id)
    assert !Kata.exists?(root_dir, id), "exists? false before created"
    Kata.create_new(root_dir, info)
    assert Kata.exists?(root_dir, id), "exists? true after created"
  end
      
  test "creating a new kata succeeds and creates katas root dir" do
    teardown    
    kata = make_kata(language)
    assert File.exists?(kata.dir), 'inner/outer dir created'
  end
  
  test "you can create an avatar in a kata" do
    teardown    
    kata = make_kata(language) 
    avatar_name = 'hippo'
    avatar = Avatar.new(kata, avatar_name)
    assert 'hippo', avatar.name
  end

end
