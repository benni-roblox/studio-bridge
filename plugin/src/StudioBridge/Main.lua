local coreGui = game:GetService("CoreGui")

local PLUGIN_NAME = "Studio Bridge"
local INTERFACE = script.Parent.StudioBridgeUI

local importing = require(script.Parent.Importing)
local protectedImport = importing.protectedImport

--------------------------------------------------------------------------------
-- Plugin Setup
--------------------------------------------------------------------------------

-- Suppresses the "unknown global" warnings.
local plugin = plugin
local toolbar = plugin:CreateToolbar(PLUGIN_NAME)

-- Global 'active' state for the Options window.
--
-- This would be better off encapsulated in a class, along with the functions to
-- show/hide the Options window.
local isOptionsWindowActive = false

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

local function initializeSettings()
  local runBefore = plugin:GetSetting("RunBefore") or false

  if not runBefore then
    plugin:SetSettings("RunBefore", true)

    plugin:SetSettings("AutoSync", false)
    plugin:SetSettings("RefreshRate", .25)
  end
end

initializeSettings()

--------------------------------------------------------------------------------
-- UI Display
--------------------------------------------------------------------------------

local function showOptionsUI()
  isOptionsWindowActive = true
  INTERFACE.Core.Visible = true
end

local function hideOptionsUI()
  isOptionsWindowActive = false
  INTERFACE.Core.Visible = false
end

--------------------------------------------------------------------------------
-- Button Setup
--------------------------------------------------------------------------------

local function createSyncButton()
  local tooltip = "Establishes a connection to the server and starts syncing "..
    "changes made on the filesystem."
  local icon = "rbxassetid://619356746"

  return toolbar:CreateButton("Sync", tooltip, icon)
end

local function setupSyncButton()
  local button = createSyncButton()

  -- We have to keep this outside of the Click event, otherwise we won't be able
  -- to debounce it and the user can run multiple auto sync loops.
  local syncing = false

  local function runImportLoop()
    local refreshRate = plugin:GetSetting("RefreshRate")

    while syncing do
      local success = protectedImport()

      if not success or not plugin:GetSetting("AutoSync") then
        syncing = false
      end

      wait(refreshRate)
    end
  end

  local function autoImport()
    if not syncing then
      syncing = true
      runImportLoop()

      -- This gets run after the above function breaks out of its loop.
      print("[StudioBridge] Auto syncing stopped")
    end

    syncing = false
  end

  button.Click:connect(function()
    if plugin:GetSetting("AutoSync") then
      print("[StudioBridge] Started auto syncing file changes. Click "..
        "\"Sync\" again to stop")

      autoImport(sycning, plugin)
    else
      print("[StudioBridge] Importing files from the server")
      protectedImport()
    end
  end)
end

local function createOptionsButton()
  local tooltip = ("Configure options for %s."):format(PLUGIN_NAME)
  local icon = "rbxassetid://619383224"

  return toolbar:CreateButton("Settings", tooltip, icon)
end

local function setupOptionsButton()
  local button = createOptionsButton()

  button.Click:connect(function()
    if isOptionsWindowActive then
      hideOptionsUI()
    else
      showOptionsUI()
    end
  end)
end

setupSyncButton()
setupOptionsButton()

--------------------------------------------------------------------------------
-- UI Functionality
--------------------------------------------------------------------------------

local RadioButton = require(script.Parent.UI.RadioButton)

local function setupCloseButton(button)
  button.MouseButton1Down:connect(hideOptionsUI)
end

local function setupAutoSyncButton(button)
  local radioButton = RadioButton.new(button, plugin:GetSetting("AutoSync"))

  radioButton.StateChanged.Event:connect(function(newState)
    plugin:SetSetting("AutoSync", newState)
  end)
end

local function setupRefreshRateField(field)
  local initialValue = plugin:GetSetting("RefreshRate")

  -- If the user doesn't press enter to save their changes, we use this to
  -- revert back to the last value.
  local prevValue = initialValue

  field.Text = initialValue

  field.FocusLost:connect(function(enterPressed)
    local newValue = tonumber(field.Text)

    if enterPressed and newValue then
      prevValue = newValue
      plugin:SetSetting("RefreshRate", newValue)
    else
      field.Text = prevValue
    end
  end)
end

local function setupUI()
  INTERFACE.Parent = coreGui
  INTERFACE.Core.Visible = false
end

local function setupUIElements()
  local options = INTERFACE.Core.Margin.Options

  setupCloseButton(INTERFACE.Core.Close)
  setupAutoSyncButton(options.AutoSync.Button)
  setupRefreshRateField(options.RefreshRate.InputField)
end

setupUI()
setupUIElements()
