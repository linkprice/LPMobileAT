Pod::Spec.new do |s|
  s.name             = "LPMobileAT"
  s.version          = "2.0"
  s.summary          = "LPMobileAT provides tracking functionality for app installation and in-app events."
  s.description      = <<-DESC
                       LinkPrice's LPMobileAT allows you to track app installation (CPI),
                       purchasing goods or services (CPS), user registration (CPA)
                       and other activities what you want.
                       DESC
  s.homepage         = "https://github.com/linkprice/LPMobileAT_iOS"
  s.license          = { :type => "Proprietary",
                         :text => <<-LICENSE
                             Copyright 2016 LinkPrice Co., Ltd. All rights reserved.
                             LICENSE
                       }
  s.author           = { "LinkPrice" => "app_dev@linkprice.com" }
  s.source           = { :git => "https://github.com/linkprice/LPMobileAT_iOS.git",
                         :tag => s.version.to_s
                       }
  s.ios.deployment_target = "9.0"
  s.ios.frameworks = "AdSupport", "Security"
  s.ios.preserve_paths = "LPMobileAT.framework"
  s.ios.vendored_frameworks = "LPMobileAT.framework"
end
