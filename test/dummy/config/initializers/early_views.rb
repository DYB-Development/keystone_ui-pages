# frozen_string_literal: true

# Loads Action View while the app boots, as host apps such as dyb_web do, so the suite catches an engine that names its own helpers too early.
ActionView::Base
