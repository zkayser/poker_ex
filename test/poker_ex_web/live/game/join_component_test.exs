defmodule PokerExWeb.Live.JoinComponentTest do
  alias PokerExWeb.Live.JoinComponent
  import Phoenix.LiveViewTest
  use ExUnit.Case

  describe "render/1" do
    test "renders an input for entering player name" do
      assert render_component(JoinComponent, id: :join, name: nil) =~ "data-testid=\"name-input\""
    end

    test "fills the input with the name passed in assigns if given" do
      assert render_component(JoinComponent, id: :join, name: "Zack") =~ "Zack"
    end

    test "makes the join game button disabled given no name" do
      assert render_component(JoinComponent, id: :join, name: nil) =~ "disabled"
    end

    test "enables the join game button if a name is given" do
      refute render_component(JoinComponent, id: :join, name: "Zack") =~ "disabled"
    end
  end
end
