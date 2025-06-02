How Rails Loads a Request (Request Lifecycle)
=============================================
  ➤ Browser sends HTTP request
  ➤ Hits the Rack middleware
  ➤ Enters Rails router (routes.rb)
  ➤ Routes to the correct controller + action
  ➤ Executes before_action filters
  ➤ Calls the action method
  ➤ Returns HTML/JSON response
  ➤ Runs after_action filters
  ➤ Response sent back to Rack → Web Server → Browser