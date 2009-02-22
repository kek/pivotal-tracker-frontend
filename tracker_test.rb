require 'tracker'
require 'test/unit'

class TrackerTest < Test::Unit::TestCase
  def setup
    @pt = Project.find($settings['projects'][0]['id'])
  end
  
  def test_get_project
    assert @pt.name.length > 0
  end
  
  def test_get_stories
    st = @pt.stories
    assert st.length > 0
  end

  def test_get_current_stories
    st = @pt.current_stories
    assert st.length > 0
  end
  
  def test_stories_to_s
    s = @pt.current_stories.to_s
    assert s.length > 0
  end
  
  def test_stories_to_html
    html = @pt.current_stories.to_html
    assert html.length > 0
  end
end
