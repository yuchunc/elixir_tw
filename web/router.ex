defmodule Elixirtaipei.Router do
  use Elixirtaipei.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Elixirtaipei do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :home
    get "/resources", PageController, :resources
    get "/social_networks", PageController, :social_networks
    get "/helps", PageController, :helps
  end

  # Other scopes may use custom stacks.
  # scope "/api", Elixirtaipei do
  #   pipe_through :api
  # end
end
