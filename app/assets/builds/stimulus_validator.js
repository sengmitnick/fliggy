// app/javascript/stimulus_validator.ts
var StimulusValidator = class {
  constructor() {
    this.registeredControllers = /* @__PURE__ */ new Set();
    this.missingControllers = /* @__PURE__ */ new Set();
    this.hasReported = false;
    this.elementIssues = /* @__PURE__ */ new Map();
    this.stimulus = window.Stimulus;
    this.initValidator();
  }
  initValidator() {
    if (!this.isDevelopment()) {
      console.log("StimulusValidator not enable in non-develop environment.");
      return;
    }
    if (!window.Stimulus) {
      console.log("StimulusValidator not enable while Stimulus not found");
      return;
    }
    this.setupStimulusErrorHandler();
    this.collectRegisteredControllers();
    this.validateOnDOMReady();
    this.interceptActionClicks();
  }
  isDevelopment() {
    return !!window.errorHandler;
  }
  setupStimulusErrorHandler() {
    const setupHandler = () => {
      const stimulus = window.Stimulus;
      if (stimulus && typeof stimulus.handleError === "undefined") {
        stimulus.handleError = (error, message, detail) => {
          console.error("Stimulus Error:", { error, message, detail });
          if (window.errorHandler) {
            let errorMessage = message || error.message || "Stimulus error occurred";
            let controllerName = "";
            let action = "";
            let subType = "scope-error";
            let suggestion = "";
            let elementInfo = null;
            if (detail) {
              if (detail.identifier) {
                controllerName = detail.identifier;
              }
              if (detail.action) {
                action = detail.action;
              }
              if (detail.element) {
                elementInfo = {
                  tagName: detail.element.tagName,
                  id: detail.element.id,
                  className: detail.element.className,
                  outerHTML: `${detail.element.outerHTML?.substring(0, 200)}...`
                };
              }
            }
            if (error.message.includes("Controller") && error.message.includes("is not defined")) {
              subType = "missing-controller";
              const controllerMatch = error.message.match(/(\w+)Controller is not defined/);
              if (controllerMatch) {
                controllerName = controllerMatch[1].toLowerCase();
                errorMessage = `Stimulus controller "${controllerName}" is not defined or not registered`;
                suggestion = `Make sure to import and register the "${controllerName}" controller in app/javascript/controllers/index.ts. Check if the controller file exists at app/javascript/controllers/${controllerName}_controller.ts`;
              }
            } else if (error.message.includes("Missing target element")) {
              subType = "missing-target";
              suggestion = "Check that the target element exists in the DOM and has the correct data-[controller]-target attribute";
            } else if (error.message.includes("Missing action")) {
              subType = "missing-action";
              suggestion = "Verify that the action method exists in the controller class and is properly defined";
            } else if (message && message.includes("click")) {
              subType = "action-click";
              suggestion = "Check if the click action handler exists and the element has the correct data-action attribute";
            }
            window.errorHandler.handleError({
              message: errorMessage,
              type: "stimulus",
              subType,
              controllerName,
              action,
              suggestion,
              elementInfo,
              details: {
                originalMessage: message,
                error: {
                  name: error.name,
                  message: error.message,
                  stack: error.stack
                },
                detail
              },
              timestamp: (/* @__PURE__ */ new Date()).toISOString(),
              filename: "stimulus-application",
              error
            });
          }
        };
        console.log("Stimulus error handling configured via stimulus_validator");
      }
    };
    if (window.Stimulus) {
      setupHandler();
    } else {
      const checkStimulus = () => {
        if (window.Stimulus) {
          setupHandler();
        } else {
          setTimeout(checkStimulus, 100);
        }
      };
      checkStimulus();
    }
  }
  collectRegisteredControllers() {
    try {
      const stimulus = window.Stimulus;
      if (stimulus?.router?.modulesByIdentifier) {
        const modules = stimulus.router.modulesByIdentifier;
        for (const [identifier] of modules) {
          this.registeredControllers.add(identifier);
        }
      }
    } catch (error) {
      console.warn("Could not access Stimulus controllers:", error);
    }
  }
  validateOnDOMReady() {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", () => this.validateControllers());
    } else {
      this.validateControllers();
    }
    this.observeNewContent();
  }
  validateControllers() {
    const elements = document.querySelectorAll("[data-controller]");
    elements.forEach((element) => {
      const controllers = element.getAttribute("data-controller")?.split(" ") || [];
      controllers.forEach((controller) => {
        const trimmedController = controller.trim();
        if (trimmedController && !this.registeredControllers.has(trimmedController)) {
          this.missingControllers.add(trimmedController);
        } else if (trimmedController && this.registeredControllers.has(trimmedController)) {
          this.validateRequiredTargets(element, trimmedController);
        }
      });
      this.validateElementPositioning(element);
    });
    if (this.missingControllers.size > 0) {
      this.reportMissingControllers();
    }
    if (this.elementIssues.size > 0) {
      this.reportElementIssues();
    }
  }
  observeNewContent() {
    const observer = new MutationObserver((mutations) => {
      let hasNewElements = false;
      mutations.forEach((mutation) => {
        if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
          const hasRelevantChanges = Array.from(mutation.addedNodes).some((node) => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              const element = node;
              if (element.id === "js-error-status-bar" || element.closest("#js-error-status-bar")) {
                return false;
              }
              return element.hasAttribute("data-controller") || element.querySelector("[data-controller]");
            }
            return false;
          });
          if (hasRelevantChanges) {
            hasNewElements = true;
          }
        }
      });
      if (hasNewElements) {
        setTimeout(() => this.validateControllers(), 100);
      }
    });
    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
  reportMissingControllers() {
    if (this.hasReported) {
      return;
    }
    const missingList = Array.from(this.missingControllers);
    this.hasReported = true;
    if (window.errorHandler) {
      window.errorHandler.handleError({
        message: `Missing Stimulus controllers: ${missingList.join(", ")}`,
        type: "stimulus",
        subType: "missing-controller",
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        missingControllers: missingList,
        suggestion: `Run: rails generate stimulus_controller ${missingList[0]}`,
        details: {
          controllers: missingList,
          generatorCommands: missingList.map((name) => `rails generate stimulus_controller ${name}`)
        }
      });
    } else {
      console.error("\u{1F534} Missing Stimulus Controllers:", missingList);
      console.info("\u{1F4A1} Generate missing controllers:", missingList.map(
        (name) => `rails generate stimulus_controller ${name}`
      ).join("\n"));
    }
  }
  validateRequiredTargets(controllerElement, controllerName) {
    try {
      const stimulus = window.Stimulus;
      if (stimulus?.router?.modulesByIdentifier) {
        const module = stimulus.router.modulesByIdentifier.get(controllerName);
        if (module) {
          const controllerClass = module.definition.controllerConstructor;
          const definedTargets = controllerClass.targets || [];
          const missingTargets = [];
          const outOfScopeTargets = [];
          const optionalTargets = this.getOptionalTargets(controllerClass);
          definedTargets.forEach((targetName) => {
            if (optionalTargets.has(targetName)) {
              return;
            }
            const targetSelector = `[data-${controllerName}-target="${targetName}"]`;
            const targetElement = controllerElement.querySelector(targetSelector);
            if (!targetElement) {
              const globalTargetElement = document.querySelector(targetSelector);
              if (globalTargetElement) {
                outOfScopeTargets.push(targetName);
              } else {
                missingTargets.push(targetName);
              }
            }
          });
          if (missingTargets.length > 0) {
            this.reportMissingTargets(controllerName, missingTargets, controllerElement);
          }
          if (outOfScopeTargets.length > 0) {
            this.reportOutOfScopeTargets(controllerName, outOfScopeTargets, controllerElement);
          }
        }
      }
    } catch (error) {
      console.warn(`Could not validate targets for controller ${controllerName}:`, error);
    }
  }
  getOptionalTargets(controllerClass) {
    const optionalTargets = /* @__PURE__ */ new Set();
    try {
      const definedTargets = controllerClass.targets || [];
      definedTargets.forEach((targetName) => {
        const capitalizedTarget = targetName.charAt(0).toUpperCase() + targetName.slice(1);
        const hasTargetProperty = `has${capitalizedTarget}Target`;
        if (hasTargetProperty in controllerClass.prototype || Object.getOwnPropertyDescriptor(controllerClass.prototype, hasTargetProperty) || Object.hasOwnProperty.call(controllerClass.prototype, hasTargetProperty)) {
          optionalTargets.add(targetName);
        }
      });
    } catch (error) {
      console.warn("Could not analyze controller for optional targets:", error);
    }
    return optionalTargets;
  }
  validateElementPositioning(controllerElement) {
    const controllerName = controllerElement.getAttribute("data-controller")?.split(" ")[0];
    if (!controllerName) return;
    const issues = [];
    this.checkCommonSelectors(controllerElement, controllerName, issues);
    if (issues.length > 0) {
      this.elementIssues.set(controllerName, issues);
    }
  }
  checkCommonSelectors(element, controllerName, issues) {
    const relevantIds = [];
    relevantIds.push(`${controllerName}-input`, `${controllerName}-button`, `${controllerName}-form`);
    relevantIds.forEach((id) => {
      const globalElement = document.getElementById(id);
      if (globalElement) {
        const isInScope = globalElement === element || element.contains(globalElement);
        if (!isInScope) {
          issues.push(`Element #${id} exists but outside controller scope`);
        }
      }
    });
  }
  interceptActionClicks() {
    document.addEventListener("click", (event) => {
      const target = event.target;
      if (!target) return;
      const actionElement = target.closest("[data-action]");
      if (!actionElement) return;
      const actions = actionElement.getAttribute("data-action")?.split(" ") || [];
      actions.forEach((action) => {
        const controllerMatch = action.match(/([\w-]+)#([\w-]+)/);
        if (controllerMatch) {
          const controllerName = controllerMatch[1];
          const methodName = controllerMatch[2];
          if (!this.registeredControllers.has(controllerName)) {
            this.reportMissingActionController(controllerName, action, actionElement);
            return;
          }
          const controllerElement = actionElement.closest(`[data-controller*="${controllerName}"]`);
          if (!controllerElement) {
            this.reportMissingControllerScope(controllerName, action, actionElement);
            return;
          }
          this.checkMethodExists(controllerName, methodName, action, actionElement);
        }
      });
    }, true);
  }
  reportMissingTargets(controllerName, missingTargets, controllerElement) {
    if (window.errorHandler) {
      const targetList = missingTargets.join(", ");
      const targetExamples = missingTargets.map(
        (target) => `<div data-${controllerName}-target="${target}">...</div>`
      ).join("\n");
      window.errorHandler.handleError({
        message: `Stimulus controller "${controllerName}" requires missing target elements: ${targetList}`,
        type: "stimulus",
        subType: "missing-target",
        controllerName,
        missingTargets,
        elementInfo: this.getElementInfo(controllerElement),
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        suggestion: `Add the required target elements to the DOM within the controller scope, or make them optional by adding 'declare readonly has${missingTargets.map((t) => t.charAt(0).toUpperCase() + t.slice(1)).join("Target: boolean, declare readonly has")}Target: boolean' to the controller`,
        details: {
          errorType: "Missing Required Targets",
          controllerName,
          missingTargets,
          requiredElements: targetExamples,
          elementInfo: this.getElementInfo(controllerElement),
          description: `The controller "${controllerName}" defines targets [${targetList}] but these elements are not found in the DOM within the controller scope`
        }
      });
    }
  }
  reportOutOfScopeTargets(controllerName, outOfScopeTargets, controllerElement) {
    if (window.errorHandler) {
      const targetList = outOfScopeTargets.join(", ");
      window.errorHandler.handleError({
        message: `Stimulus controller "${controllerName}" targets exist but are outside controller scope: ${targetList}`,
        type: "stimulus",
        subType: "target-scope-error",
        controllerName,
        outOfScopeTargets,
        elementInfo: this.getElementInfo(controllerElement),
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        suggestion: `Move target elements inside controller scope or expand controller scope to include targets`,
        details: {
          errorType: "Targets Outside Controller Scope",
          controllerName,
          outOfScopeTargets,
          elementInfo: this.getElementInfo(controllerElement),
          description: `The controller "${controllerName}" defines targets [${targetList}] and these elements exist in the DOM but are outside the controller scope`,
          solution: `Either move the target elements inside the controller scope, or expand the controller scope to include the targets by moving the data-controller attribute to a parent element that contains both the controller logic and the target elements.`
        }
      });
    }
  }
  reportMissingActionController(controllerName, action, element) {
    if (window.errorHandler) {
      window.errorHandler.handleError({
        message: `User clicked action "${action}" but controller "${controllerName}" is not registered`,
        type: "stimulus",
        subType: "action-click",
        controllerName,
        action,
        elementInfo: this.getElementInfo(element),
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        suggestion: `Run: rails generate stimulus_controller ${controllerName}`,
        details: {
          errorType: "Missing Controller on Action Click",
          controllerName,
          action,
          elementInfo: this.getElementInfo(element),
          description: "User attempted to trigger an action but the required controller is not registered"
        }
      });
    }
  }
  reportMissingControllerScope(controllerName, action, element) {
    if (window.errorHandler) {
      window.errorHandler.handleError({
        message: `User clicked action "${action}" but no "${controllerName}" controller found in parent scope`,
        type: "stimulus",
        subType: "scope-error",
        controllerName,
        action,
        elementInfo: this.getElementInfo(element),
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        suggestion: `Add data-controller="${controllerName}" to a parent element or move this element inside the controller scope`,
        details: {
          errorType: "Controller Scope Missing",
          controllerName,
          action,
          elementInfo: this.getElementInfo(element),
          description: "Action element is not within the scope of its target controller",
          solution: `Wrap the element with <div data-controller="${controllerName}">...</div>`
        }
      });
    }
  }
  checkMethodExists(controllerName, methodName, action, element) {
    try {
      const stimulus = window.Stimulus;
      if (stimulus?.router?.modulesByIdentifier) {
        const module = stimulus.router.modulesByIdentifier.get(controllerName);
        if (module) {
          const controllerClass = module.definition.controllerConstructor;
          const instance = new controllerClass();
          if (typeof instance[methodName] !== "function") {
            this.reportMissingMethod(controllerName, methodName, action, element);
          }
        }
      }
    } catch (_error) {
      this.checkMethodExistsAlternative(controllerName, methodName, action, element);
    }
  }
  checkMethodExistsAlternative(controllerName, methodName, action, element) {
    try {
      const stimulus = window.Stimulus;
      if (stimulus?.router?.modulesByIdentifier) {
        const module = stimulus.router.modulesByIdentifier.get(controllerName);
        if (module) {
          const controllerClass = module.definition.controllerConstructor;
          if (!controllerClass.prototype[methodName] || typeof controllerClass.prototype[methodName] !== "function") {
            this.reportMissingMethod(controllerName, methodName, action, element);
          }
        }
      }
    } catch (error) {
      console.warn(`Could not validate method existence for ${controllerName}#${methodName}:`, error);
    }
  }
  reportMissingMethod(controllerName, methodName, action, element) {
    if (window.errorHandler) {
      window.errorHandler.handleError({
        message: `User clicked action "${action}" but method "${methodName}" does not exist in controller "${controllerName}"`,
        type: "stimulus",
        subType: "method-not-found",
        controllerName,
        methodName,
        action,
        elementInfo: this.getElementInfo(element),
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        suggestion: `Add method "${methodName}" to the ${controllerName} controller or fix the action name`,
        details: {
          errorType: "Method Not Found",
          controllerName,
          methodName,
          action,
          elementInfo: this.getElementInfo(element),
          description: `The method "${methodName}" was called but does not exist in the controller`,
          solution: `Add the method to your controller:

${methodName}(): void {
  // Your implementation here
}`
        }
      });
    }
  }
  reportElementIssues() {
    const allIssues = [];
    const detailedIssues = {};
    this.elementIssues.forEach((issues, controllerName) => {
      allIssues.push(`${controllerName}: ${issues.join(", ")}`);
      detailedIssues[controllerName] = issues;
    });
    if (window.errorHandler) {
      window.errorHandler.handleError({
        message: `Stimulus element positioning issues detected`,
        type: "stimulus",
        subType: "positioning-issues",
        positioningIssues: allIssues,
        timestamp: (/* @__PURE__ */ new Date()).toISOString(),
        suggestion: "Consider using data-targets or moving elements inside controller scope",
        details: {
          errorType: "Element Positioning Issues",
          controllers: Object.keys(detailedIssues),
          issuesByController: detailedIssues,
          totalIssues: allIssues.length,
          description: "Some elements are referenced by controllers but exist outside their scope",
          possibleSolutions: [
            "Move elements inside controller scope",
            "Use data-targets for external elements",
            "Check controller data-controller attribute placement"
          ]
        }
      });
    }
    this.elementIssues.clear();
  }
  getElementInfo(element) {
    return {
      tagName: element.tagName.toLowerCase(),
      id: element.id || "no-id",
      className: element.className || "no-class",
      textContent: (element.textContent || "").substring(0, 50)
    };
  }
  // Public API
  getRegisteredControllers() {
    return Array.from(this.registeredControllers);
  }
  getMissingControllers() {
    return Array.from(this.missingControllers);
  }
  forceValidation() {
    this.missingControllers.clear();
    this.elementIssues.clear();
    this.hasReported = false;
    this.validateControllers();
  }
};
if (typeof window !== "undefined") {
  window.stimulusValidator = new StimulusValidator();
}
var stimulus_validator_default = StimulusValidator;
export {
  stimulus_validator_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vamF2YXNjcmlwdC9zdGltdWx1c192YWxpZGF0b3IudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbIi8vIFN0aW11bHVzIENvbnRyb2xsZXIgVmFsaWRhdG9yXG4vLyBDaGVja3MgZm9yIG1pc3Npbmcgc3RpbXVsdXMgY29udHJvbGxlcnMgcmVmZXJlbmNlZCBpbiB2aWV3c1xuXG5jbGFzcyBTdGltdWx1c1ZhbGlkYXRvciB7XG4gIHByaXZhdGUgcmVnaXN0ZXJlZENvbnRyb2xsZXJzOiBTZXQ8c3RyaW5nPiA9IG5ldyBTZXQoKTtcbiAgcHJpdmF0ZSBtaXNzaW5nQ29udHJvbGxlcnM6IFNldDxzdHJpbmc+ID0gbmV3IFNldCgpO1xuICBwcml2YXRlIGhhc1JlcG9ydGVkOiBib29sZWFuID0gZmFsc2U7XG4gIHByaXZhdGUgZWxlbWVudElzc3VlczogTWFwPHN0cmluZywgc3RyaW5nW10+ID0gbmV3IE1hcCgpO1xuICBwcml2YXRlIHN0aW11bHVzID0gd2luZG93LlN0aW11bHVzO1xuXG4gIGNvbnN0cnVjdG9yKCkge1xuICAgIHRoaXMuaW5pdFZhbGlkYXRvcigpO1xuICB9XG5cbiAgcHJpdmF0ZSBpbml0VmFsaWRhdG9yKCk6IHZvaWQge1xuICAgIC8vIE9ubHkgcnVuIGluIGRldmVsb3BtZW50IGVudmlyb25tZW50XG4gICAgLy9cbiAgICBpZiAoIXRoaXMuaXNEZXZlbG9wbWVudCgpKSB7XG4gICAgICBjb25zb2xlLmxvZygnU3RpbXVsdXNWYWxpZGF0b3Igbm90IGVuYWJsZSBpbiBub24tZGV2ZWxvcCBlbnZpcm9ubWVudC4nKVxuICAgICAgcmV0dXJuXG4gICAgfVxuXG4gICAgaWYgKCF3aW5kb3cuU3RpbXVsdXMpIHtcbiAgICAgIGNvbnNvbGUubG9nKCdTdGltdWx1c1ZhbGlkYXRvciBub3QgZW5hYmxlIHdoaWxlIFN0aW11bHVzIG5vdCBmb3VuZCcpXG4gICAgICByZXR1cm5cbiAgICB9XG5cbiAgICB0aGlzLnNldHVwU3RpbXVsdXNFcnJvckhhbmRsZXIoKTtcbiAgICB0aGlzLmNvbGxlY3RSZWdpc3RlcmVkQ29udHJvbGxlcnMoKTtcbiAgICB0aGlzLnZhbGlkYXRlT25ET01SZWFkeSgpO1xuICAgIHRoaXMuaW50ZXJjZXB0QWN0aW9uQ2xpY2tzKCk7XG4gIH1cblxuICBwcml2YXRlIGlzRGV2ZWxvcG1lbnQoKTogYm9vbGVhbiB7XG4gICAgcmV0dXJuICEhd2luZG93LmVycm9ySGFuZGxlclxuICB9XG5cbiAgcHJpdmF0ZSBzZXR1cFN0aW11bHVzRXJyb3JIYW5kbGVyKCk6IHZvaWQge1xuICAgIC8vIFNldHVwIFN0aW11bHVzIGFwcGxpY2F0aW9uIGVycm9yIGhhbmRsaW5nIHVzaW5nIGFwcGxpY2F0aW9uLmhhbmRsZUVycm9yXG4gICAgY29uc3Qgc2V0dXBIYW5kbGVyID0gKCkgPT4ge1xuICAgICAgY29uc3Qgc3RpbXVsdXMgPSB3aW5kb3cuU3RpbXVsdXMgYXMgYW55O1xuICAgICAgaWYgKHN0aW11bHVzICYmIHR5cGVvZiBzdGltdWx1cy5oYW5kbGVFcnJvciA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgc3RpbXVsdXMuaGFuZGxlRXJyb3IgPSAoZXJyb3I6IEVycm9yLCBtZXNzYWdlOiBzdHJpbmcsIGRldGFpbDogYW55KSA9PiB7XG4gICAgICAgICAgY29uc29sZS5lcnJvcignU3RpbXVsdXMgRXJyb3I6JywgeyBlcnJvciwgbWVzc2FnZSwgZGV0YWlsIH0pO1xuXG4gICAgICAgICAgLy8gVXNlIHRoZSBnbG9iYWwgZXJyb3IgaGFuZGxlciB0byBjYXB0dXJlIFN0aW11bHVzIGVycm9yc1xuICAgICAgICAgIGlmICh3aW5kb3cuZXJyb3JIYW5kbGVyKSB7XG4gICAgICAgICAgICBsZXQgZXJyb3JNZXNzYWdlID0gbWVzc2FnZSB8fCBlcnJvci5tZXNzYWdlIHx8ICdTdGltdWx1cyBlcnJvciBvY2N1cnJlZCc7XG4gICAgICAgICAgICBsZXQgY29udHJvbGxlck5hbWUgPSAnJztcbiAgICAgICAgICAgIGxldCBhY3Rpb24gPSAnJztcbiAgICAgICAgICAgIGxldCBzdWJUeXBlOiAnbWlzc2luZy1jb250cm9sbGVyJyB8ICdzY29wZS1lcnJvcicgfCAncG9zaXRpb25pbmctaXNzdWVzJyB8ICdhY3Rpb24tY2xpY2snIHwgJ21pc3NpbmctdGFyZ2V0JyB8ICdtaXNzaW5nLWFjdGlvbicgfCAnbWV0aG9kLW5vdC1mb3VuZCcgPSAnc2NvcGUtZXJyb3InO1xuICAgICAgICAgICAgbGV0IHN1Z2dlc3Rpb24gPSAnJztcbiAgICAgICAgICAgIGxldCBlbGVtZW50SW5mbyA9IG51bGw7XG5cbiAgICAgICAgICAgIC8vIEV4dHJhY3QgY29udHJvbGxlciBhbmQgYWN0aW9uIGluZm9ybWF0aW9uIGZyb20gZGV0YWlsIG9yIGVycm9yIGNvbnRleHRcbiAgICAgICAgICAgIGlmIChkZXRhaWwpIHtcbiAgICAgICAgICAgICAgaWYgKGRldGFpbC5pZGVudGlmaWVyKSB7XG4gICAgICAgICAgICAgICAgY29udHJvbGxlck5hbWUgPSBkZXRhaWwuaWRlbnRpZmllcjtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICBpZiAoZGV0YWlsLmFjdGlvbikge1xuICAgICAgICAgICAgICAgIGFjdGlvbiA9IGRldGFpbC5hY3Rpb247XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgaWYgKGRldGFpbC5lbGVtZW50KSB7XG4gICAgICAgICAgICAgICAgZWxlbWVudEluZm8gPSB7XG4gICAgICAgICAgICAgICAgICB0YWdOYW1lOiBkZXRhaWwuZWxlbWVudC50YWdOYW1lLFxuICAgICAgICAgICAgICAgICAgaWQ6IGRldGFpbC5lbGVtZW50LmlkLFxuICAgICAgICAgICAgICAgICAgY2xhc3NOYW1lOiBkZXRhaWwuZWxlbWVudC5jbGFzc05hbWUsXG4gICAgICAgICAgICAgICAgICBvdXRlckhUTUw6IGAke2RldGFpbC5lbGVtZW50Lm91dGVySFRNTD8uc3Vic3RyaW5nKDAsIDIwMCkgIH0uLi5gXG4gICAgICAgICAgICAgICAgfTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAvLyBBbmFseXplIGVycm9yIHR5cGUgYW5kIHByb3ZpZGUgc3BlY2lmaWMgc3VnZ2VzdGlvbnNcbiAgICAgICAgICAgIGlmIChlcnJvci5tZXNzYWdlLmluY2x1ZGVzKCdDb250cm9sbGVyJykgJiYgZXJyb3IubWVzc2FnZS5pbmNsdWRlcygnaXMgbm90IGRlZmluZWQnKSkge1xuICAgICAgICAgICAgICBzdWJUeXBlID0gJ21pc3NpbmctY29udHJvbGxlcic7XG4gICAgICAgICAgICAgIGNvbnN0IGNvbnRyb2xsZXJNYXRjaCA9IGVycm9yLm1lc3NhZ2UubWF0Y2goLyhcXHcrKUNvbnRyb2xsZXIgaXMgbm90IGRlZmluZWQvKTtcbiAgICAgICAgICAgICAgaWYgKGNvbnRyb2xsZXJNYXRjaCkge1xuICAgICAgICAgICAgICAgIGNvbnRyb2xsZXJOYW1lID0gY29udHJvbGxlck1hdGNoWzFdLnRvTG93ZXJDYXNlKCk7XG4gICAgICAgICAgICAgICAgZXJyb3JNZXNzYWdlID0gYFN0aW11bHVzIGNvbnRyb2xsZXIgXCIke2NvbnRyb2xsZXJOYW1lfVwiIGlzIG5vdCBkZWZpbmVkIG9yIG5vdCByZWdpc3RlcmVkYDtcbiAgICAgICAgICAgICAgICBzdWdnZXN0aW9uID0gYE1ha2Ugc3VyZSB0byBpbXBvcnQgYW5kIHJlZ2lzdGVyIHRoZSBcIiR7Y29udHJvbGxlck5hbWV9XCIgY29udHJvbGxlciBpbiBhcHAvamF2YXNjcmlwdC9jb250cm9sbGVycy9pbmRleC50cy4gYCArXG4gICAgICAgICAgICAgICAgICBgQ2hlY2sgaWYgdGhlIGNvbnRyb2xsZXIgZmlsZSBleGlzdHMgYXQgYXBwL2phdmFzY3JpcHQvY29udHJvbGxlcnMvJHtjb250cm9sbGVyTmFtZX1fY29udHJvbGxlci50c2A7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0gZWxzZSBpZiAoZXJyb3IubWVzc2FnZS5pbmNsdWRlcygnTWlzc2luZyB0YXJnZXQgZWxlbWVudCcpKSB7XG4gICAgICAgICAgICAgIHN1YlR5cGUgPSAnbWlzc2luZy10YXJnZXQnO1xuICAgICAgICAgICAgICBzdWdnZXN0aW9uID0gJ0NoZWNrIHRoYXQgdGhlIHRhcmdldCBlbGVtZW50IGV4aXN0cyBpbiB0aGUgRE9NIGFuZCBoYXMgdGhlIGNvcnJlY3QgZGF0YS1bY29udHJvbGxlcl0tdGFyZ2V0IGF0dHJpYnV0ZSc7XG4gICAgICAgICAgICB9IGVsc2UgaWYgKGVycm9yLm1lc3NhZ2UuaW5jbHVkZXMoJ01pc3NpbmcgYWN0aW9uJykpIHtcbiAgICAgICAgICAgICAgc3ViVHlwZSA9ICdtaXNzaW5nLWFjdGlvbic7XG4gICAgICAgICAgICAgIHN1Z2dlc3Rpb24gPSAnVmVyaWZ5IHRoYXQgdGhlIGFjdGlvbiBtZXRob2QgZXhpc3RzIGluIHRoZSBjb250cm9sbGVyIGNsYXNzIGFuZCBpcyBwcm9wZXJseSBkZWZpbmVkJztcbiAgICAgICAgICAgIH0gZWxzZSBpZiAobWVzc2FnZSAmJiBtZXNzYWdlLmluY2x1ZGVzKCdjbGljaycpKSB7XG4gICAgICAgICAgICAgIHN1YlR5cGUgPSAnYWN0aW9uLWNsaWNrJztcbiAgICAgICAgICAgICAgc3VnZ2VzdGlvbiA9ICdDaGVjayBpZiB0aGUgY2xpY2sgYWN0aW9uIGhhbmRsZXIgZXhpc3RzIGFuZCB0aGUgZWxlbWVudCBoYXMgdGhlIGNvcnJlY3QgZGF0YS1hY3Rpb24gYXR0cmlidXRlJztcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgLy8gUmVwb3J0IHRoZSBlcnJvciB0byB0aGUgZXJyb3IgaGFuZGxlclxuICAgICAgICAgICAgd2luZG93LmVycm9ySGFuZGxlci5oYW5kbGVFcnJvcih7XG4gICAgICAgICAgICAgIG1lc3NhZ2U6IGVycm9yTWVzc2FnZSxcbiAgICAgICAgICAgICAgdHlwZTogJ3N0aW11bHVzJyxcbiAgICAgICAgICAgICAgc3ViVHlwZTogc3ViVHlwZSxcbiAgICAgICAgICAgICAgY29udHJvbGxlck5hbWU6IGNvbnRyb2xsZXJOYW1lLFxuICAgICAgICAgICAgICBhY3Rpb246IGFjdGlvbixcbiAgICAgICAgICAgICAgc3VnZ2VzdGlvbjogc3VnZ2VzdGlvbixcbiAgICAgICAgICAgICAgZWxlbWVudEluZm86IGVsZW1lbnRJbmZvLFxuICAgICAgICAgICAgICBkZXRhaWxzOiB7XG4gICAgICAgICAgICAgICAgb3JpZ2luYWxNZXNzYWdlOiBtZXNzYWdlLFxuICAgICAgICAgICAgICAgIGVycm9yOiB7XG4gICAgICAgICAgICAgICAgICBuYW1lOiBlcnJvci5uYW1lLFxuICAgICAgICAgICAgICAgICAgbWVzc2FnZTogZXJyb3IubWVzc2FnZSxcbiAgICAgICAgICAgICAgICAgIHN0YWNrOiBlcnJvci5zdGFja1xuICAgICAgICAgICAgICAgIH0sXG4gICAgICAgICAgICAgICAgZGV0YWlsOiBkZXRhaWxcbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgdGltZXN0YW1wOiBuZXcgRGF0ZSgpLnRvSVNPU3RyaW5nKCksXG4gICAgICAgICAgICAgIGZpbGVuYW1lOiAnc3RpbXVsdXMtYXBwbGljYXRpb24nLFxuICAgICAgICAgICAgICBlcnJvcjogZXJyb3JcbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgIH1cbiAgICAgICAgfTtcblxuICAgICAgICBjb25zb2xlLmxvZygnU3RpbXVsdXMgZXJyb3IgaGFuZGxpbmcgY29uZmlndXJlZCB2aWEgc3RpbXVsdXNfdmFsaWRhdG9yJyk7XG4gICAgICB9XG4gICAgfTtcblxuICAgIC8vIFRyeSB0byBzZXR1cCBpbW1lZGlhdGVseSBpZiBTdGltdWx1cyBpcyBhbHJlYWR5IGF2YWlsYWJsZVxuICAgIGlmICh3aW5kb3cuU3RpbXVsdXMpIHtcbiAgICAgIHNldHVwSGFuZGxlcigpO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBXYWl0IGZvciBTdGltdWx1cyB0byBiZSBhdmFpbGFibGVcbiAgICAgIGNvbnN0IGNoZWNrU3RpbXVsdXMgPSAoKSA9PiB7XG4gICAgICAgIGlmICh3aW5kb3cuU3RpbXVsdXMpIHtcbiAgICAgICAgICBzZXR1cEhhbmRsZXIoKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBzZXRUaW1lb3V0KGNoZWNrU3RpbXVsdXMsIDEwMCk7XG4gICAgICAgIH1cbiAgICAgIH07XG4gICAgICBjaGVja1N0aW11bHVzKCk7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBjb2xsZWN0UmVnaXN0ZXJlZENvbnRyb2xsZXJzKCk6IHZvaWQge1xuICAgIC8vIEdldCByZWdpc3RlcmVkIGNvbnRyb2xsZXJzIGZyb20gU3RpbXVsdXMgYXBwbGljYXRpb25cbiAgICB0cnkge1xuICAgICAgY29uc3Qgc3RpbXVsdXMgPSB3aW5kb3cuU3RpbXVsdXMgYXMgYW55O1xuICAgICAgaWYgKHN0aW11bHVzPy5yb3V0ZXI/Lm1vZHVsZXNCeUlkZW50aWZpZXIpIHtcbiAgICAgICAgY29uc3QgbW9kdWxlcyA9IHN0aW11bHVzLnJvdXRlci5tb2R1bGVzQnlJZGVudGlmaWVyO1xuICAgICAgICBmb3IgKGNvbnN0IFtpZGVudGlmaWVyXSBvZiBtb2R1bGVzKSB7XG4gICAgICAgICAgdGhpcy5yZWdpc3RlcmVkQ29udHJvbGxlcnMuYWRkKGlkZW50aWZpZXIpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgIGNvbnNvbGUud2FybignQ291bGQgbm90IGFjY2VzcyBTdGltdWx1cyBjb250cm9sbGVyczonLCBlcnJvcik7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSB2YWxpZGF0ZU9uRE9NUmVhZHkoKTogdm9pZCB7XG4gICAgaWYgKGRvY3VtZW50LnJlYWR5U3RhdGUgPT09ICdsb2FkaW5nJykge1xuICAgICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcignRE9NQ29udGVudExvYWRlZCcsICgpID0+IHRoaXMudmFsaWRhdGVDb250cm9sbGVycygpKTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy52YWxpZGF0ZUNvbnRyb2xsZXJzKCk7XG4gICAgfVxuXG4gICAgLy8gQWxzbyB2YWxpZGF0ZSB3aGVuIG5ldyBjb250ZW50IGlzIGFkZGVkIGR5bmFtaWNhbGx5XG4gICAgdGhpcy5vYnNlcnZlTmV3Q29udGVudCgpO1xuICB9XG5cbiAgcHJpdmF0ZSB2YWxpZGF0ZUNvbnRyb2xsZXJzKCk6IHZvaWQge1xuICAgIGNvbnN0IGVsZW1lbnRzID0gZG9jdW1lbnQucXVlcnlTZWxlY3RvckFsbCgnW2RhdGEtY29udHJvbGxlcl0nKTtcblxuICAgIGVsZW1lbnRzLmZvckVhY2goZWxlbWVudCA9PiB7XG4gICAgICBjb25zdCBjb250cm9sbGVycyA9IGVsZW1lbnQuZ2V0QXR0cmlidXRlKCdkYXRhLWNvbnRyb2xsZXInKT8uc3BsaXQoJyAnKSB8fCBbXTtcblxuICAgICAgY29udHJvbGxlcnMuZm9yRWFjaChjb250cm9sbGVyID0+IHtcbiAgICAgICAgY29uc3QgdHJpbW1lZENvbnRyb2xsZXIgPSBjb250cm9sbGVyLnRyaW0oKTtcbiAgICAgICAgaWYgKHRyaW1tZWRDb250cm9sbGVyICYmICF0aGlzLnJlZ2lzdGVyZWRDb250cm9sbGVycy5oYXModHJpbW1lZENvbnRyb2xsZXIpKSB7XG4gICAgICAgICAgdGhpcy5taXNzaW5nQ29udHJvbGxlcnMuYWRkKHRyaW1tZWRDb250cm9sbGVyKTtcbiAgICAgICAgfSBlbHNlIGlmICh0cmltbWVkQ29udHJvbGxlciAmJiB0aGlzLnJlZ2lzdGVyZWRDb250cm9sbGVycy5oYXModHJpbW1lZENvbnRyb2xsZXIpKSB7XG4gICAgICAgICAgLy8gVmFsaWRhdGUgcmVxdWlyZWQgdGFyZ2V0cyBmb3IgcmVnaXN0ZXJlZCBjb250cm9sbGVyc1xuICAgICAgICAgIHRoaXMudmFsaWRhdGVSZXF1aXJlZFRhcmdldHMoZWxlbWVudCwgdHJpbW1lZENvbnRyb2xsZXIpO1xuICAgICAgICB9XG4gICAgICB9KTtcblxuICAgICAgLy8gVmFsaWRhdGUgZWxlbWVudCBwb3NpdGlvbmluZyBpc3N1ZXNcbiAgICAgIHRoaXMudmFsaWRhdGVFbGVtZW50UG9zaXRpb25pbmcoZWxlbWVudCk7XG4gICAgfSk7XG5cbiAgICBpZiAodGhpcy5taXNzaW5nQ29udHJvbGxlcnMuc2l6ZSA+IDApIHtcbiAgICAgIHRoaXMucmVwb3J0TWlzc2luZ0NvbnRyb2xsZXJzKCk7XG4gICAgfVxuXG4gICAgaWYgKHRoaXMuZWxlbWVudElzc3Vlcy5zaXplID4gMCkge1xuICAgICAgdGhpcy5yZXBvcnRFbGVtZW50SXNzdWVzKCk7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBvYnNlcnZlTmV3Q29udGVudCgpOiB2b2lkIHtcbiAgICBjb25zdCBvYnNlcnZlciA9IG5ldyBNdXRhdGlvbk9ic2VydmVyKG11dGF0aW9ucyA9PiB7XG4gICAgICBsZXQgaGFzTmV3RWxlbWVudHMgPSBmYWxzZTtcblxuICAgICAgbXV0YXRpb25zLmZvckVhY2gobXV0YXRpb24gPT4ge1xuICAgICAgICBpZiAobXV0YXRpb24udHlwZSA9PT0gJ2NoaWxkTGlzdCcgJiYgbXV0YXRpb24uYWRkZWROb2Rlcy5sZW5ndGggPiAwKSB7XG4gICAgICAgICAgLy8gSWdub3JlIGVycm9yIGhhbmRsZXIgVUkgY2hhbmdlcyB0byBwcmV2ZW50IGluZmluaXRlIGxvb3BzXG4gICAgICAgICAgY29uc3QgaGFzUmVsZXZhbnRDaGFuZ2VzID0gQXJyYXkuZnJvbShtdXRhdGlvbi5hZGRlZE5vZGVzKS5zb21lKG5vZGUgPT4ge1xuICAgICAgICAgICAgaWYgKG5vZGUubm9kZVR5cGUgPT09IE5vZGUuRUxFTUVOVF9OT0RFKSB7XG4gICAgICAgICAgICAgIGNvbnN0IGVsZW1lbnQgPSBub2RlIGFzIEVsZW1lbnQ7XG4gICAgICAgICAgICAgIC8vIFNraXAgZXJyb3IgaGFuZGxlciBlbGVtZW50c1xuICAgICAgICAgICAgICBpZiAoZWxlbWVudC5pZCA9PT0gJ2pzLWVycm9yLXN0YXR1cy1iYXInIHx8XG4gICAgICAgICAgICAgICAgICBlbGVtZW50LmNsb3Nlc3QoJyNqcy1lcnJvci1zdGF0dXMtYmFyJykpIHtcbiAgICAgICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgLy8gT25seSBjYXJlIGFib3V0IGVsZW1lbnRzIHdpdGggZGF0YS1jb250cm9sbGVyIGF0dHJpYnV0ZXNcbiAgICAgICAgICAgICAgcmV0dXJuIGVsZW1lbnQuaGFzQXR0cmlidXRlKCdkYXRhLWNvbnRyb2xsZXInKSB8fFxuICAgICAgICAgICAgICAgICAgICAgZWxlbWVudC5xdWVyeVNlbGVjdG9yKCdbZGF0YS1jb250cm9sbGVyXScpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgaWYgKGhhc1JlbGV2YW50Q2hhbmdlcykge1xuICAgICAgICAgICAgaGFzTmV3RWxlbWVudHMgPSB0cnVlO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfSk7XG5cbiAgICAgIGlmIChoYXNOZXdFbGVtZW50cykge1xuICAgICAgICBzZXRUaW1lb3V0KCgpID0+IHRoaXMudmFsaWRhdGVDb250cm9sbGVycygpLCAxMDApO1xuICAgICAgfVxuICAgIH0pO1xuXG4gICAgb2JzZXJ2ZXIub2JzZXJ2ZShkb2N1bWVudC5ib2R5LCB7XG4gICAgICBjaGlsZExpc3Q6IHRydWUsXG4gICAgICBzdWJ0cmVlOiB0cnVlXG4gICAgfSk7XG4gIH1cblxuICBwcml2YXRlIHJlcG9ydE1pc3NpbmdDb250cm9sbGVycygpOiB2b2lkIHtcbiAgICAvLyBQcmV2ZW50IGR1cGxpY2F0ZSByZXBvcnRzXG4gICAgaWYgKHRoaXMuaGFzUmVwb3J0ZWQpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICBjb25zdCBtaXNzaW5nTGlzdCA9IEFycmF5LmZyb20odGhpcy5taXNzaW5nQ29udHJvbGxlcnMpO1xuICAgIHRoaXMuaGFzUmVwb3J0ZWQgPSB0cnVlO1xuXG4gICAgLy8gUmVwb3J0IHRvIGVycm9yIGhhbmRsZXIgaWYgYXZhaWxhYmxlXG4gICAgaWYgKHdpbmRvdy5lcnJvckhhbmRsZXIpIHtcbiAgICAgIHdpbmRvdy5lcnJvckhhbmRsZXIuaGFuZGxlRXJyb3Ioe1xuICAgICAgICBtZXNzYWdlOiBgTWlzc2luZyBTdGltdWx1cyBjb250cm9sbGVyczogJHttaXNzaW5nTGlzdC5qb2luKCcsICcpfWAsXG4gICAgICAgIHR5cGU6ICdzdGltdWx1cycsXG4gICAgICAgIHN1YlR5cGU6ICdtaXNzaW5nLWNvbnRyb2xsZXInLFxuICAgICAgICB0aW1lc3RhbXA6IG5ldyBEYXRlKCkudG9JU09TdHJpbmcoKSxcbiAgICAgICAgbWlzc2luZ0NvbnRyb2xsZXJzOiBtaXNzaW5nTGlzdCxcbiAgICAgICAgc3VnZ2VzdGlvbjogYFJ1bjogcmFpbHMgZ2VuZXJhdGUgc3RpbXVsdXNfY29udHJvbGxlciAke21pc3NpbmdMaXN0WzBdfWAsXG4gICAgICAgIGRldGFpbHM6IHtcbiAgICAgICAgICBjb250cm9sbGVyczogbWlzc2luZ0xpc3QsXG4gICAgICAgICAgZ2VuZXJhdG9yQ29tbWFuZHM6IG1pc3NpbmdMaXN0Lm1hcChuYW1lID0+IGByYWlscyBnZW5lcmF0ZSBzdGltdWx1c19jb250cm9sbGVyICR7bmFtZX1gKVxuICAgICAgICB9XG4gICAgICB9KTtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gRmFsbGJhY2sgdG8gY29uc29sZVxuICAgICAgY29uc29sZS5lcnJvcignXHVEODNEXHVERDM0IE1pc3NpbmcgU3RpbXVsdXMgQ29udHJvbGxlcnM6JywgbWlzc2luZ0xpc3QpO1xuICAgICAgY29uc29sZS5pbmZvKCdcdUQ4M0RcdURDQTEgR2VuZXJhdGUgbWlzc2luZyBjb250cm9sbGVyczonLCBtaXNzaW5nTGlzdC5tYXAobmFtZSA9PlxuICAgICAgICBgcmFpbHMgZ2VuZXJhdGUgc3RpbXVsdXNfY29udHJvbGxlciAke25hbWV9YFxuICAgICAgKS5qb2luKCdcXG4nKSk7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSB2YWxpZGF0ZVJlcXVpcmVkVGFyZ2V0cyhjb250cm9sbGVyRWxlbWVudDogRWxlbWVudCwgY29udHJvbGxlck5hbWU6IHN0cmluZyk6IHZvaWQge1xuICAgIHRyeSB7XG4gICAgICBjb25zdCBzdGltdWx1cyA9IHdpbmRvdy5TdGltdWx1cyBhcyBhbnk7XG4gICAgICBpZiAoc3RpbXVsdXM/LnJvdXRlcj8ubW9kdWxlc0J5SWRlbnRpZmllcikge1xuICAgICAgICBjb25zdCBtb2R1bGUgPSBzdGltdWx1cy5yb3V0ZXIubW9kdWxlc0J5SWRlbnRpZmllci5nZXQoY29udHJvbGxlck5hbWUpO1xuICAgICAgICBpZiAobW9kdWxlKSB7XG4gICAgICAgICAgY29uc3QgY29udHJvbGxlckNsYXNzID0gbW9kdWxlLmRlZmluaXRpb24uY29udHJvbGxlckNvbnN0cnVjdG9yO1xuXG4gICAgICAgICAgY29uc3QgZGVmaW5lZFRhcmdldHMgPSBjb250cm9sbGVyQ2xhc3MudGFyZ2V0cyB8fCBbXTtcbiAgICAgICAgICBjb25zdCBtaXNzaW5nVGFyZ2V0czogc3RyaW5nW10gPSBbXTtcbiAgICAgICAgICBjb25zdCBvdXRPZlNjb3BlVGFyZ2V0czogc3RyaW5nW10gPSBbXTtcblxuICAgICAgICAgIC8vIEdldCBvcHRpb25hbCB0YXJnZXRzIGJ5IGNoZWNraW5nIGZvciBoYXNYWFhUYXJnZXQgcHJvcGVydGllc1xuICAgICAgICAgIGNvbnN0IG9wdGlvbmFsVGFyZ2V0cyA9IHRoaXMuZ2V0T3B0aW9uYWxUYXJnZXRzKGNvbnRyb2xsZXJDbGFzcyk7XG5cbiAgICAgICAgICBkZWZpbmVkVGFyZ2V0cy5mb3JFYWNoKCh0YXJnZXROYW1lOiBzdHJpbmcpID0+IHtcbiAgICAgICAgICAgIC8vIFNraXAgdmFsaWRhdGlvbiBmb3Igb3B0aW9uYWwgdGFyZ2V0c1xuICAgICAgICAgICAgaWYgKG9wdGlvbmFsVGFyZ2V0cy5oYXModGFyZ2V0TmFtZSkpIHtcbiAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBjb25zdCB0YXJnZXRTZWxlY3RvciA9IGBbZGF0YS0ke2NvbnRyb2xsZXJOYW1lfS10YXJnZXQ9XCIke3RhcmdldE5hbWV9XCJdYDtcbiAgICAgICAgICAgIGNvbnN0IHRhcmdldEVsZW1lbnQgPSBjb250cm9sbGVyRWxlbWVudC5xdWVyeVNlbGVjdG9yKHRhcmdldFNlbGVjdG9yKTtcblxuICAgICAgICAgICAgaWYgKCF0YXJnZXRFbGVtZW50KSB7XG4gICAgICAgICAgICAgIC8vIENoZWNrIGlmIHRhcmdldCBleGlzdHMgZ2xvYmFsbHkgYnV0IG91dHNpZGUgY29udHJvbGxlciBzY29wZVxuICAgICAgICAgICAgICBjb25zdCBnbG9iYWxUYXJnZXRFbGVtZW50ID0gZG9jdW1lbnQucXVlcnlTZWxlY3Rvcih0YXJnZXRTZWxlY3Rvcik7XG4gICAgICAgICAgICAgIGlmIChnbG9iYWxUYXJnZXRFbGVtZW50KSB7XG4gICAgICAgICAgICAgICAgb3V0T2ZTY29wZVRhcmdldHMucHVzaCh0YXJnZXROYW1lKTtcbiAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBtaXNzaW5nVGFyZ2V0cy5wdXNoKHRhcmdldE5hbWUpO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSk7XG5cbiAgICAgICAgICBpZiAobWlzc2luZ1RhcmdldHMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgdGhpcy5yZXBvcnRNaXNzaW5nVGFyZ2V0cyhjb250cm9sbGVyTmFtZSwgbWlzc2luZ1RhcmdldHMsIGNvbnRyb2xsZXJFbGVtZW50KTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAob3V0T2ZTY29wZVRhcmdldHMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgdGhpcy5yZXBvcnRPdXRPZlNjb3BlVGFyZ2V0cyhjb250cm9sbGVyTmFtZSwgb3V0T2ZTY29wZVRhcmdldHMsIGNvbnRyb2xsZXJFbGVtZW50KTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgY29uc29sZS53YXJuKGBDb3VsZCBub3QgdmFsaWRhdGUgdGFyZ2V0cyBmb3IgY29udHJvbGxlciAke2NvbnRyb2xsZXJOYW1lfTpgLCBlcnJvcik7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBnZXRPcHRpb25hbFRhcmdldHMoY29udHJvbGxlckNsYXNzOiBhbnkpOiBTZXQ8c3RyaW5nPiB7XG4gICAgY29uc3Qgb3B0aW9uYWxUYXJnZXRzID0gbmV3IFNldDxzdHJpbmc+KCk7XG5cbiAgICB0cnkge1xuICAgICAgLy8gR2V0IGRlZmluZWQgdGFyZ2V0c1xuICAgICAgY29uc3QgZGVmaW5lZFRhcmdldHMgPSBjb250cm9sbGVyQ2xhc3MudGFyZ2V0cyB8fCBbXTtcblxuICAgICAgZGVmaW5lZFRhcmdldHMuZm9yRWFjaCgodGFyZ2V0TmFtZTogc3RyaW5nKSA9PiB7XG4gICAgICAgIC8vIENvbnZlcnQgdGFyZ2V0IG5hbWUgdG8gaGFzWFhYVGFyZ2V0IHByb3BlcnR5IG5hbWVcbiAgICAgICAgY29uc3QgY2FwaXRhbGl6ZWRUYXJnZXQgPSB0YXJnZXROYW1lLmNoYXJBdCgwKS50b1VwcGVyQ2FzZSgpICsgdGFyZ2V0TmFtZS5zbGljZSgxKTtcbiAgICAgICAgY29uc3QgaGFzVGFyZ2V0UHJvcGVydHkgPSBgaGFzJHtjYXBpdGFsaXplZFRhcmdldH1UYXJnZXRgO1xuXG4gICAgICAgIC8vIENoZWNrIGlmIGhhc1hYWFRhcmdldCBpcyBkZWNsYXJlZCBhcyBhIHByb3BlcnR5IG9uIHRoZSBjbGFzc1xuICAgICAgICAvLyBUaGlzIGluZGljYXRlcyB0aGUgdGFyZ2V0IGlzIG9wdGlvbmFsXG4gICAgICAgIGlmIChoYXNUYXJnZXRQcm9wZXJ0eSBpbiBjb250cm9sbGVyQ2xhc3MucHJvdG90eXBlIHx8XG4gICAgICAgICAgICBPYmplY3QuZ2V0T3duUHJvcGVydHlEZXNjcmlwdG9yKGNvbnRyb2xsZXJDbGFzcy5wcm90b3R5cGUsIGhhc1RhcmdldFByb3BlcnR5KSB8fFxuICAgICAgICAgICAgT2JqZWN0Lmhhc093blByb3BlcnR5LmNhbGwoY29udHJvbGxlckNsYXNzLnByb3RvdHlwZSwgaGFzVGFyZ2V0UHJvcGVydHkpKSB7XG4gICAgICAgICAgb3B0aW9uYWxUYXJnZXRzLmFkZCh0YXJnZXROYW1lKTtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgIGNvbnNvbGUud2FybignQ291bGQgbm90IGFuYWx5emUgY29udHJvbGxlciBmb3Igb3B0aW9uYWwgdGFyZ2V0czonLCBlcnJvcik7XG4gICAgfVxuXG4gICAgcmV0dXJuIG9wdGlvbmFsVGFyZ2V0cztcbiAgfVxuXG4gIHByaXZhdGUgdmFsaWRhdGVFbGVtZW50UG9zaXRpb25pbmcoY29udHJvbGxlckVsZW1lbnQ6IEVsZW1lbnQpOiB2b2lkIHtcbiAgICBjb25zdCBjb250cm9sbGVyTmFtZSA9IGNvbnRyb2xsZXJFbGVtZW50LmdldEF0dHJpYnV0ZSgnZGF0YS1jb250cm9sbGVyJyk/LnNwbGl0KCcgJylbMF07XG4gICAgaWYgKCFjb250cm9sbGVyTmFtZSkgcmV0dXJuO1xuXG4gICAgY29uc3QgaXNzdWVzOiBzdHJpbmdbXSA9IFtdO1xuXG4gICAgdGhpcy5jaGVja0NvbW1vblNlbGVjdG9ycyhjb250cm9sbGVyRWxlbWVudCwgY29udHJvbGxlck5hbWUsIGlzc3Vlcyk7XG5cbiAgICBpZiAoaXNzdWVzLmxlbmd0aCA+IDApIHtcbiAgICAgIHRoaXMuZWxlbWVudElzc3Vlcy5zZXQoY29udHJvbGxlck5hbWUsIGlzc3Vlcyk7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSBjaGVja0NvbW1vblNlbGVjdG9ycyhlbGVtZW50OiBFbGVtZW50LCBjb250cm9sbGVyTmFtZTogc3RyaW5nLCBpc3N1ZXM6IHN0cmluZ1tdKTogdm9pZCB7XG4gICAgY29uc3QgcmVsZXZhbnRJZHM6IHN0cmluZ1tdID0gW107XG5cbiAgICByZWxldmFudElkcy5wdXNoKGAke2NvbnRyb2xsZXJOYW1lfS1pbnB1dGAsIGAke2NvbnRyb2xsZXJOYW1lfS1idXR0b25gLCBgJHtjb250cm9sbGVyTmFtZX0tZm9ybWApO1xuXG4gICAgcmVsZXZhbnRJZHMuZm9yRWFjaChpZCA9PiB7XG4gICAgICBjb25zdCBnbG9iYWxFbGVtZW50ID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoaWQpO1xuICAgICAgaWYgKGdsb2JhbEVsZW1lbnQpIHtcbiAgICAgICAgY29uc3QgaXNJblNjb3BlID0gZ2xvYmFsRWxlbWVudCA9PT0gZWxlbWVudCB8fCBlbGVtZW50LmNvbnRhaW5zKGdsb2JhbEVsZW1lbnQpO1xuXG4gICAgICAgIGlmICghaXNJblNjb3BlKSB7XG4gICAgICAgICAgaXNzdWVzLnB1c2goYEVsZW1lbnQgIyR7aWR9IGV4aXN0cyBidXQgb3V0c2lkZSBjb250cm9sbGVyIHNjb3BlYCk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9KTtcbiAgfVxuXG4gIHByaXZhdGUgaW50ZXJjZXB0QWN0aW9uQ2xpY2tzKCk6IHZvaWQge1xuICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ2NsaWNrJywgKGV2ZW50KSA9PiB7XG4gICAgICBjb25zdCB0YXJnZXQgPSBldmVudC50YXJnZXQgYXMgRWxlbWVudDtcbiAgICAgIGlmICghdGFyZ2V0KSByZXR1cm47XG5cbiAgICAgIGNvbnN0IGFjdGlvbkVsZW1lbnQgPSB0YXJnZXQuY2xvc2VzdCgnW2RhdGEtYWN0aW9uXScpO1xuICAgICAgaWYgKCFhY3Rpb25FbGVtZW50KSByZXR1cm47XG5cbiAgICAgIGNvbnN0IGFjdGlvbnMgPSBhY3Rpb25FbGVtZW50LmdldEF0dHJpYnV0ZSgnZGF0YS1hY3Rpb24nKT8uc3BsaXQoJyAnKSB8fCBbXTtcblxuICAgICAgYWN0aW9ucy5mb3JFYWNoKGFjdGlvbiA9PiB7XG4gICAgICAgIGNvbnN0IGNvbnRyb2xsZXJNYXRjaCA9IGFjdGlvbi5tYXRjaCgvKFtcXHctXSspIyhbXFx3LV0rKS8pO1xuICAgICAgICBpZiAoY29udHJvbGxlck1hdGNoKSB7XG4gICAgICAgICAgY29uc3QgY29udHJvbGxlck5hbWUgPSBjb250cm9sbGVyTWF0Y2hbMV07XG4gICAgICAgICAgY29uc3QgbWV0aG9kTmFtZSA9IGNvbnRyb2xsZXJNYXRjaFsyXTtcblxuICAgICAgICAgIGlmICghdGhpcy5yZWdpc3RlcmVkQ29udHJvbGxlcnMuaGFzKGNvbnRyb2xsZXJOYW1lKSkge1xuICAgICAgICAgICAgdGhpcy5yZXBvcnRNaXNzaW5nQWN0aW9uQ29udHJvbGxlcihjb250cm9sbGVyTmFtZSwgYWN0aW9uLCBhY3Rpb25FbGVtZW50KTtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjb25zdCBjb250cm9sbGVyRWxlbWVudCA9IGFjdGlvbkVsZW1lbnQuY2xvc2VzdChgW2RhdGEtY29udHJvbGxlcio9XCIke2NvbnRyb2xsZXJOYW1lfVwiXWApO1xuICAgICAgICAgIGlmICghY29udHJvbGxlckVsZW1lbnQpIHtcbiAgICAgICAgICAgIHRoaXMucmVwb3J0TWlzc2luZ0NvbnRyb2xsZXJTY29wZShjb250cm9sbGVyTmFtZSwgYWN0aW9uLCBhY3Rpb25FbGVtZW50KTtcbiAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICB0aGlzLmNoZWNrTWV0aG9kRXhpc3RzKGNvbnRyb2xsZXJOYW1lLCBtZXRob2ROYW1lLCBhY3Rpb24sIGFjdGlvbkVsZW1lbnQpO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICB9LCB0cnVlKTtcbiAgfVxuXG4gIHByaXZhdGUgcmVwb3J0TWlzc2luZ1RhcmdldHMoY29udHJvbGxlck5hbWU6IHN0cmluZywgbWlzc2luZ1RhcmdldHM6IHN0cmluZ1tdLCBjb250cm9sbGVyRWxlbWVudDogRWxlbWVudCk6IHZvaWQge1xuICAgIGlmICh3aW5kb3cuZXJyb3JIYW5kbGVyKSB7XG4gICAgICBjb25zdCB0YXJnZXRMaXN0ID0gbWlzc2luZ1RhcmdldHMuam9pbignLCAnKTtcbiAgICAgIGNvbnN0IHRhcmdldEV4YW1wbGVzID0gbWlzc2luZ1RhcmdldHMubWFwKHRhcmdldCA9PlxuICAgICAgICBgPGRpdiBkYXRhLSR7Y29udHJvbGxlck5hbWV9LXRhcmdldD1cIiR7dGFyZ2V0fVwiPi4uLjwvZGl2PmBcbiAgICAgICkuam9pbignXFxuJyk7XG5cbiAgICAgIHdpbmRvdy5lcnJvckhhbmRsZXIuaGFuZGxlRXJyb3Ioe1xuICAgICAgICBtZXNzYWdlOiBgU3RpbXVsdXMgY29udHJvbGxlciBcIiR7Y29udHJvbGxlck5hbWV9XCIgcmVxdWlyZXMgbWlzc2luZyB0YXJnZXQgZWxlbWVudHM6ICR7dGFyZ2V0TGlzdH1gLFxuICAgICAgICB0eXBlOiAnc3RpbXVsdXMnLFxuICAgICAgICBzdWJUeXBlOiAnbWlzc2luZy10YXJnZXQnLFxuICAgICAgICBjb250cm9sbGVyTmFtZSxcbiAgICAgICAgbWlzc2luZ1RhcmdldHMsXG4gICAgICAgIGVsZW1lbnRJbmZvOiB0aGlzLmdldEVsZW1lbnRJbmZvKGNvbnRyb2xsZXJFbGVtZW50KSxcbiAgICAgICAgdGltZXN0YW1wOiBuZXcgRGF0ZSgpLnRvSVNPU3RyaW5nKCksXG4gICAgICAgIHN1Z2dlc3Rpb246IGBBZGQgdGhlIHJlcXVpcmVkIHRhcmdldCBlbGVtZW50cyB0byB0aGUgRE9NIHdpdGhpbiB0aGUgY29udHJvbGxlciBzY29wZSwgb3IgbWFrZSB0aGVtIG9wdGlvbmFsIGJ5IGFkZGluZyBgICtcbiAgICAgICAgICBgJ2RlY2xhcmUgcmVhZG9ubHkgaGFzJHttaXNzaW5nVGFyZ2V0cy5tYXAodCA9PiB0LmNoYXJBdCgwKS50b1VwcGVyQ2FzZSgpICsgdC5zbGljZSgxKSkuam9pbignVGFyZ2V0OiBib29sZWFuLCBkZWNsYXJlIHJlYWRvbmx5IGhhcycpfVRhcmdldDogYm9vbGVhbicgdG8gdGhlIGNvbnRyb2xsZXJgLFxuICAgICAgICBkZXRhaWxzOiB7XG4gICAgICAgICAgZXJyb3JUeXBlOiAnTWlzc2luZyBSZXF1aXJlZCBUYXJnZXRzJyxcbiAgICAgICAgICBjb250cm9sbGVyTmFtZSxcbiAgICAgICAgICBtaXNzaW5nVGFyZ2V0cyxcbiAgICAgICAgICByZXF1aXJlZEVsZW1lbnRzOiB0YXJnZXRFeGFtcGxlcyxcbiAgICAgICAgICBlbGVtZW50SW5mbzogdGhpcy5nZXRFbGVtZW50SW5mbyhjb250cm9sbGVyRWxlbWVudCksXG4gICAgICAgICAgZGVzY3JpcHRpb246IGBUaGUgY29udHJvbGxlciBcIiR7Y29udHJvbGxlck5hbWV9XCIgZGVmaW5lcyB0YXJnZXRzIFske3RhcmdldExpc3R9XSBidXQgdGhlc2UgZWxlbWVudHMgYXJlIG5vdCBmb3VuZCBpbiB0aGUgRE9NIHdpdGhpbiB0aGUgY29udHJvbGxlciBzY29wZWBcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSByZXBvcnRPdXRPZlNjb3BlVGFyZ2V0cyhjb250cm9sbGVyTmFtZTogc3RyaW5nLCBvdXRPZlNjb3BlVGFyZ2V0czogc3RyaW5nW10sIGNvbnRyb2xsZXJFbGVtZW50OiBFbGVtZW50KTogdm9pZCB7XG4gICAgaWYgKHdpbmRvdy5lcnJvckhhbmRsZXIpIHtcbiAgICAgIGNvbnN0IHRhcmdldExpc3QgPSBvdXRPZlNjb3BlVGFyZ2V0cy5qb2luKCcsICcpO1xuXG4gICAgICB3aW5kb3cuZXJyb3JIYW5kbGVyLmhhbmRsZUVycm9yKHtcbiAgICAgICAgbWVzc2FnZTogYFN0aW11bHVzIGNvbnRyb2xsZXIgXCIke2NvbnRyb2xsZXJOYW1lfVwiIHRhcmdldHMgZXhpc3QgYnV0IGFyZSBvdXRzaWRlIGNvbnRyb2xsZXIgc2NvcGU6ICR7dGFyZ2V0TGlzdH1gLFxuICAgICAgICB0eXBlOiAnc3RpbXVsdXMnLFxuICAgICAgICBzdWJUeXBlOiAndGFyZ2V0LXNjb3BlLWVycm9yJyxcbiAgICAgICAgY29udHJvbGxlck5hbWUsXG4gICAgICAgIG91dE9mU2NvcGVUYXJnZXRzLFxuICAgICAgICBlbGVtZW50SW5mbzogdGhpcy5nZXRFbGVtZW50SW5mbyhjb250cm9sbGVyRWxlbWVudCksXG4gICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpLFxuICAgICAgICBzdWdnZXN0aW9uOiBgTW92ZSB0YXJnZXQgZWxlbWVudHMgaW5zaWRlIGNvbnRyb2xsZXIgc2NvcGUgb3IgZXhwYW5kIGNvbnRyb2xsZXIgc2NvcGUgdG8gaW5jbHVkZSB0YXJnZXRzYCxcbiAgICAgICAgZGV0YWlsczoge1xuICAgICAgICAgIGVycm9yVHlwZTogJ1RhcmdldHMgT3V0c2lkZSBDb250cm9sbGVyIFNjb3BlJyxcbiAgICAgICAgICBjb250cm9sbGVyTmFtZSxcbiAgICAgICAgICBvdXRPZlNjb3BlVGFyZ2V0cyxcbiAgICAgICAgICBlbGVtZW50SW5mbzogdGhpcy5nZXRFbGVtZW50SW5mbyhjb250cm9sbGVyRWxlbWVudCksXG4gICAgICAgICAgZGVzY3JpcHRpb246IGBUaGUgY29udHJvbGxlciBcIiR7Y29udHJvbGxlck5hbWV9XCIgZGVmaW5lcyB0YXJnZXRzIFske3RhcmdldExpc3R9XSBhbmQgdGhlc2UgZWxlbWVudHMgZXhpc3QgaW4gdGhlIERPTSBidXQgYXJlIG91dHNpZGUgdGhlIGNvbnRyb2xsZXIgc2NvcGVgLFxuICAgICAgICAgIHNvbHV0aW9uOiBgRWl0aGVyIG1vdmUgdGhlIHRhcmdldCBlbGVtZW50cyBpbnNpZGUgdGhlIGNvbnRyb2xsZXIgc2NvcGUsIG9yIGV4cGFuZCB0aGUgY29udHJvbGxlciBzY29wZSB0byBpbmNsdWRlIGAgK1xuICAgICAgICAgICAgYHRoZSB0YXJnZXRzIGJ5IG1vdmluZyB0aGUgZGF0YS1jb250cm9sbGVyIGF0dHJpYnV0ZSB0byBhIHBhcmVudCBlbGVtZW50IHRoYXQgY29udGFpbnMgYm90aCB0aGUgY29udHJvbGxlciBsb2dpYyBhbmQgdGhlIHRhcmdldCBlbGVtZW50cy5gXG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgcmVwb3J0TWlzc2luZ0FjdGlvbkNvbnRyb2xsZXIoY29udHJvbGxlck5hbWU6IHN0cmluZywgYWN0aW9uOiBzdHJpbmcsIGVsZW1lbnQ6IEVsZW1lbnQpOiB2b2lkIHtcbiAgICBpZiAod2luZG93LmVycm9ySGFuZGxlcikge1xuICAgICAgd2luZG93LmVycm9ySGFuZGxlci5oYW5kbGVFcnJvcih7XG4gICAgICAgIG1lc3NhZ2U6IGBVc2VyIGNsaWNrZWQgYWN0aW9uIFwiJHthY3Rpb259XCIgYnV0IGNvbnRyb2xsZXIgXCIke2NvbnRyb2xsZXJOYW1lfVwiIGlzIG5vdCByZWdpc3RlcmVkYCxcbiAgICAgICAgdHlwZTogJ3N0aW11bHVzJyxcbiAgICAgICAgc3ViVHlwZTogJ2FjdGlvbi1jbGljaycsXG4gICAgICAgIGNvbnRyb2xsZXJOYW1lLFxuICAgICAgICBhY3Rpb24sXG4gICAgICAgIGVsZW1lbnRJbmZvOiB0aGlzLmdldEVsZW1lbnRJbmZvKGVsZW1lbnQpLFxuICAgICAgICB0aW1lc3RhbXA6IG5ldyBEYXRlKCkudG9JU09TdHJpbmcoKSxcbiAgICAgICAgc3VnZ2VzdGlvbjogYFJ1bjogcmFpbHMgZ2VuZXJhdGUgc3RpbXVsdXNfY29udHJvbGxlciAke2NvbnRyb2xsZXJOYW1lfWAsXG4gICAgICAgIGRldGFpbHM6IHtcbiAgICAgICAgICBlcnJvclR5cGU6ICdNaXNzaW5nIENvbnRyb2xsZXIgb24gQWN0aW9uIENsaWNrJyxcbiAgICAgICAgICBjb250cm9sbGVyTmFtZSxcbiAgICAgICAgICBhY3Rpb24sXG4gICAgICAgICAgZWxlbWVudEluZm86IHRoaXMuZ2V0RWxlbWVudEluZm8oZWxlbWVudCksXG4gICAgICAgICAgZGVzY3JpcHRpb246ICdVc2VyIGF0dGVtcHRlZCB0byB0cmlnZ2VyIGFuIGFjdGlvbiBidXQgdGhlIHJlcXVpcmVkIGNvbnRyb2xsZXIgaXMgbm90IHJlZ2lzdGVyZWQnXG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgcmVwb3J0TWlzc2luZ0NvbnRyb2xsZXJTY29wZShjb250cm9sbGVyTmFtZTogc3RyaW5nLCBhY3Rpb246IHN0cmluZywgZWxlbWVudDogRWxlbWVudCk6IHZvaWQge1xuICAgIGlmICh3aW5kb3cuZXJyb3JIYW5kbGVyKSB7XG4gICAgICB3aW5kb3cuZXJyb3JIYW5kbGVyLmhhbmRsZUVycm9yKHtcbiAgICAgICAgbWVzc2FnZTogYFVzZXIgY2xpY2tlZCBhY3Rpb24gXCIke2FjdGlvbn1cIiBidXQgbm8gXCIke2NvbnRyb2xsZXJOYW1lfVwiIGNvbnRyb2xsZXIgZm91bmQgaW4gcGFyZW50IHNjb3BlYCxcbiAgICAgICAgdHlwZTogJ3N0aW11bHVzJyxcbiAgICAgICAgc3ViVHlwZTogJ3Njb3BlLWVycm9yJyxcbiAgICAgICAgY29udHJvbGxlck5hbWUsXG4gICAgICAgIGFjdGlvbixcbiAgICAgICAgZWxlbWVudEluZm86IHRoaXMuZ2V0RWxlbWVudEluZm8oZWxlbWVudCksXG4gICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpLFxuICAgICAgICBzdWdnZXN0aW9uOiBgQWRkIGRhdGEtY29udHJvbGxlcj1cIiR7Y29udHJvbGxlck5hbWV9XCIgdG8gYSBwYXJlbnQgZWxlbWVudCBvciBtb3ZlIHRoaXMgZWxlbWVudCBpbnNpZGUgdGhlIGNvbnRyb2xsZXIgc2NvcGVgLFxuICAgICAgICBkZXRhaWxzOiB7XG4gICAgICAgICAgZXJyb3JUeXBlOiAnQ29udHJvbGxlciBTY29wZSBNaXNzaW5nJyxcbiAgICAgICAgICBjb250cm9sbGVyTmFtZSxcbiAgICAgICAgICBhY3Rpb24sXG4gICAgICAgICAgZWxlbWVudEluZm86IHRoaXMuZ2V0RWxlbWVudEluZm8oZWxlbWVudCksXG4gICAgICAgICAgZGVzY3JpcHRpb246ICdBY3Rpb24gZWxlbWVudCBpcyBub3Qgd2l0aGluIHRoZSBzY29wZSBvZiBpdHMgdGFyZ2V0IGNvbnRyb2xsZXInLFxuICAgICAgICAgIHNvbHV0aW9uOiBgV3JhcCB0aGUgZWxlbWVudCB3aXRoIDxkaXYgZGF0YS1jb250cm9sbGVyPVwiJHtjb250cm9sbGVyTmFtZX1cIj4uLi48L2Rpdj5gXG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgY2hlY2tNZXRob2RFeGlzdHMoY29udHJvbGxlck5hbWU6IHN0cmluZywgbWV0aG9kTmFtZTogc3RyaW5nLCBhY3Rpb246IHN0cmluZywgZWxlbWVudDogRWxlbWVudCk6IHZvaWQge1xuICAgIHRyeSB7XG4gICAgICAvLyBHZXQgdGhlIGFjdHVhbCBjb250cm9sbGVyIGluc3RhbmNlIGZyb20gU3RpbXVsdXNcbiAgICAgIGNvbnN0IHN0aW11bHVzID0gd2luZG93LlN0aW11bHVzIGFzIGFueTtcbiAgICAgIGlmIChzdGltdWx1cz8ucm91dGVyPy5tb2R1bGVzQnlJZGVudGlmaWVyKSB7XG4gICAgICAgIGNvbnN0IG1vZHVsZSA9IHN0aW11bHVzLnJvdXRlci5tb2R1bGVzQnlJZGVudGlmaWVyLmdldChjb250cm9sbGVyTmFtZSk7XG4gICAgICAgIGlmIChtb2R1bGUpIHtcbiAgICAgICAgICBjb25zdCBjb250cm9sbGVyQ2xhc3MgPSBtb2R1bGUuZGVmaW5pdGlvbi5jb250cm9sbGVyQ29uc3RydWN0b3I7XG4gICAgICAgICAgY29uc3QgaW5zdGFuY2UgPSBuZXcgY29udHJvbGxlckNsYXNzKCk7XG5cbiAgICAgICAgICAvLyBDaGVjayBpZiBtZXRob2QgZXhpc3RzIGFuZCBpcyBjYWxsYWJsZVxuICAgICAgICAgIGlmICh0eXBlb2YgaW5zdGFuY2VbbWV0aG9kTmFtZV0gIT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgICAgIHRoaXMucmVwb3J0TWlzc2luZ01ldGhvZChjb250cm9sbGVyTmFtZSwgbWV0aG9kTmFtZSwgYWN0aW9uLCBlbGVtZW50KTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9IGNhdGNoIChfZXJyb3IpIHtcbiAgICAgIC8vIElmIHdlIGNhbid0IGluc3RhbnRpYXRlIHRoZSBjb250cm9sbGVyLCB0cnkgYWx0ZXJuYXRpdmUgYXBwcm9hY2hcbiAgICAgIHRoaXMuY2hlY2tNZXRob2RFeGlzdHNBbHRlcm5hdGl2ZShjb250cm9sbGVyTmFtZSwgbWV0aG9kTmFtZSwgYWN0aW9uLCBlbGVtZW50KTtcbiAgICB9XG4gIH1cblxuICBwcml2YXRlIGNoZWNrTWV0aG9kRXhpc3RzQWx0ZXJuYXRpdmUoY29udHJvbGxlck5hbWU6IHN0cmluZywgbWV0aG9kTmFtZTogc3RyaW5nLCBhY3Rpb246IHN0cmluZywgZWxlbWVudDogRWxlbWVudCk6IHZvaWQge1xuICAgIC8vIFRyeSB0byBnZXQgY29udHJvbGxlciBjb25zdHJ1Y3RvciBkaXJlY3RseVxuICAgIHRyeSB7XG4gICAgICBjb25zdCBzdGltdWx1cyA9IHdpbmRvdy5TdGltdWx1cyBhcyBhbnk7XG4gICAgICBpZiAoc3RpbXVsdXM/LnJvdXRlcj8ubW9kdWxlc0J5SWRlbnRpZmllcikge1xuICAgICAgICBjb25zdCBtb2R1bGUgPSBzdGltdWx1cy5yb3V0ZXIubW9kdWxlc0J5SWRlbnRpZmllci5nZXQoY29udHJvbGxlck5hbWUpO1xuICAgICAgICBpZiAobW9kdWxlKSB7XG4gICAgICAgICAgY29uc3QgY29udHJvbGxlckNsYXNzID0gbW9kdWxlLmRlZmluaXRpb24uY29udHJvbGxlckNvbnN0cnVjdG9yO1xuXG4gICAgICAgICAgLy8gQ2hlY2sgcHJvdG90eXBlIGZvciBtZXRob2RcbiAgICAgICAgICBpZiAoIWNvbnRyb2xsZXJDbGFzcy5wcm90b3R5cGVbbWV0aG9kTmFtZV0gfHwgdHlwZW9mIGNvbnRyb2xsZXJDbGFzcy5wcm90b3R5cGVbbWV0aG9kTmFtZV0gIT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgICAgIHRoaXMucmVwb3J0TWlzc2luZ01ldGhvZChjb250cm9sbGVyTmFtZSwgbWV0aG9kTmFtZSwgYWN0aW9uLCBlbGVtZW50KTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9IGNhdGNoIChlcnJvcikge1xuICAgICAgY29uc29sZS53YXJuKGBDb3VsZCBub3QgdmFsaWRhdGUgbWV0aG9kIGV4aXN0ZW5jZSBmb3IgJHtjb250cm9sbGVyTmFtZX0jJHttZXRob2ROYW1lfTpgLCBlcnJvcik7XG4gICAgfVxuICB9XG5cbiAgcHJpdmF0ZSByZXBvcnRNaXNzaW5nTWV0aG9kKGNvbnRyb2xsZXJOYW1lOiBzdHJpbmcsIG1ldGhvZE5hbWU6IHN0cmluZywgYWN0aW9uOiBzdHJpbmcsIGVsZW1lbnQ6IEVsZW1lbnQpOiB2b2lkIHtcbiAgICBpZiAod2luZG93LmVycm9ySGFuZGxlcikge1xuICAgICAgd2luZG93LmVycm9ySGFuZGxlci5oYW5kbGVFcnJvcih7XG4gICAgICAgIG1lc3NhZ2U6IGBVc2VyIGNsaWNrZWQgYWN0aW9uIFwiJHthY3Rpb259XCIgYnV0IG1ldGhvZCBcIiR7bWV0aG9kTmFtZX1cIiBkb2VzIG5vdCBleGlzdCBpbiBjb250cm9sbGVyIFwiJHtjb250cm9sbGVyTmFtZX1cImAsXG4gICAgICAgIHR5cGU6ICdzdGltdWx1cycsXG4gICAgICAgIHN1YlR5cGU6ICdtZXRob2Qtbm90LWZvdW5kJyxcbiAgICAgICAgY29udHJvbGxlck5hbWUsXG4gICAgICAgIG1ldGhvZE5hbWUsXG4gICAgICAgIGFjdGlvbixcbiAgICAgICAgZWxlbWVudEluZm86IHRoaXMuZ2V0RWxlbWVudEluZm8oZWxlbWVudCksXG4gICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpLFxuICAgICAgICBzdWdnZXN0aW9uOiBgQWRkIG1ldGhvZCBcIiR7bWV0aG9kTmFtZX1cIiB0byB0aGUgJHtjb250cm9sbGVyTmFtZX0gY29udHJvbGxlciBvciBmaXggdGhlIGFjdGlvbiBuYW1lYCxcbiAgICAgICAgZGV0YWlsczoge1xuICAgICAgICAgIGVycm9yVHlwZTogJ01ldGhvZCBOb3QgRm91bmQnLFxuICAgICAgICAgIGNvbnRyb2xsZXJOYW1lLFxuICAgICAgICAgIG1ldGhvZE5hbWUsXG4gICAgICAgICAgYWN0aW9uLFxuICAgICAgICAgIGVsZW1lbnRJbmZvOiB0aGlzLmdldEVsZW1lbnRJbmZvKGVsZW1lbnQpLFxuICAgICAgICAgIGRlc2NyaXB0aW9uOiBgVGhlIG1ldGhvZCBcIiR7bWV0aG9kTmFtZX1cIiB3YXMgY2FsbGVkIGJ1dCBkb2VzIG5vdCBleGlzdCBpbiB0aGUgY29udHJvbGxlcmAsXG4gICAgICAgICAgc29sdXRpb246IGBBZGQgdGhlIG1ldGhvZCB0byB5b3VyIGNvbnRyb2xsZXI6XFxuXFxuJHttZXRob2ROYW1lfSgpOiB2b2lkIHtcXG4gIC8vIFlvdXIgaW1wbGVtZW50YXRpb24gaGVyZVxcbn1gXG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIHByaXZhdGUgcmVwb3J0RWxlbWVudElzc3VlcygpOiB2b2lkIHtcbiAgICBjb25zdCBhbGxJc3N1ZXM6IHN0cmluZ1tdID0gW107XG4gICAgY29uc3QgZGV0YWlsZWRJc3N1ZXM6IHsgW2tleTogc3RyaW5nXTogc3RyaW5nW10gfSA9IHt9O1xuXG4gICAgdGhpcy5lbGVtZW50SXNzdWVzLmZvckVhY2goKGlzc3VlcywgY29udHJvbGxlck5hbWUpID0+IHtcbiAgICAgIGFsbElzc3Vlcy5wdXNoKGAke2NvbnRyb2xsZXJOYW1lfTogJHtpc3N1ZXMuam9pbignLCAnKX1gKTtcbiAgICAgIGRldGFpbGVkSXNzdWVzW2NvbnRyb2xsZXJOYW1lXSA9IGlzc3VlcztcbiAgICB9KTtcblxuICAgIGlmICh3aW5kb3cuZXJyb3JIYW5kbGVyKSB7XG4gICAgICB3aW5kb3cuZXJyb3JIYW5kbGVyLmhhbmRsZUVycm9yKHtcbiAgICAgICAgbWVzc2FnZTogYFN0aW11bHVzIGVsZW1lbnQgcG9zaXRpb25pbmcgaXNzdWVzIGRldGVjdGVkYCxcbiAgICAgICAgdHlwZTogJ3N0aW11bHVzJyxcbiAgICAgICAgc3ViVHlwZTogJ3Bvc2l0aW9uaW5nLWlzc3VlcycsXG4gICAgICAgIHBvc2l0aW9uaW5nSXNzdWVzOiBhbGxJc3N1ZXMsXG4gICAgICAgIHRpbWVzdGFtcDogbmV3IERhdGUoKS50b0lTT1N0cmluZygpLFxuICAgICAgICBzdWdnZXN0aW9uOiAnQ29uc2lkZXIgdXNpbmcgZGF0YS10YXJnZXRzIG9yIG1vdmluZyBlbGVtZW50cyBpbnNpZGUgY29udHJvbGxlciBzY29wZScsXG4gICAgICAgIGRldGFpbHM6IHtcbiAgICAgICAgICBlcnJvclR5cGU6ICdFbGVtZW50IFBvc2l0aW9uaW5nIElzc3VlcycsXG4gICAgICAgICAgY29udHJvbGxlcnM6IE9iamVjdC5rZXlzKGRldGFpbGVkSXNzdWVzKSxcbiAgICAgICAgICBpc3N1ZXNCeUNvbnRyb2xsZXI6IGRldGFpbGVkSXNzdWVzLFxuICAgICAgICAgIHRvdGFsSXNzdWVzOiBhbGxJc3N1ZXMubGVuZ3RoLFxuICAgICAgICAgIGRlc2NyaXB0aW9uOiAnU29tZSBlbGVtZW50cyBhcmUgcmVmZXJlbmNlZCBieSBjb250cm9sbGVycyBidXQgZXhpc3Qgb3V0c2lkZSB0aGVpciBzY29wZScsXG4gICAgICAgICAgcG9zc2libGVTb2x1dGlvbnM6IFtcbiAgICAgICAgICAgICdNb3ZlIGVsZW1lbnRzIGluc2lkZSBjb250cm9sbGVyIHNjb3BlJyxcbiAgICAgICAgICAgICdVc2UgZGF0YS10YXJnZXRzIGZvciBleHRlcm5hbCBlbGVtZW50cycsXG4gICAgICAgICAgICAnQ2hlY2sgY29udHJvbGxlciBkYXRhLWNvbnRyb2xsZXIgYXR0cmlidXRlIHBsYWNlbWVudCdcbiAgICAgICAgICBdXG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cblxuICAgIHRoaXMuZWxlbWVudElzc3Vlcy5jbGVhcigpO1xuICB9XG5cbiAgcHJpdmF0ZSBnZXRFbGVtZW50SW5mbyhlbGVtZW50OiBFbGVtZW50KTogb2JqZWN0IHtcbiAgICByZXR1cm4ge1xuICAgICAgdGFnTmFtZTogZWxlbWVudC50YWdOYW1lLnRvTG93ZXJDYXNlKCksXG4gICAgICBpZDogZWxlbWVudC5pZCB8fCAnbm8taWQnLFxuICAgICAgY2xhc3NOYW1lOiBlbGVtZW50LmNsYXNzTmFtZSB8fCAnbm8tY2xhc3MnLFxuICAgICAgdGV4dENvbnRlbnQ6IChlbGVtZW50LnRleHRDb250ZW50IHx8ICcnKS5zdWJzdHJpbmcoMCwgNTApXG4gICAgfTtcbiAgfVxuXG4gIC8vIFB1YmxpYyBBUElcbiAgcHVibGljIGdldFJlZ2lzdGVyZWRDb250cm9sbGVycygpOiBzdHJpbmdbXSB7XG4gICAgcmV0dXJuIEFycmF5LmZyb20odGhpcy5yZWdpc3RlcmVkQ29udHJvbGxlcnMpO1xuICB9XG5cbiAgcHVibGljIGdldE1pc3NpbmdDb250cm9sbGVycygpOiBzdHJpbmdbXSB7XG4gICAgcmV0dXJuIEFycmF5LmZyb20odGhpcy5taXNzaW5nQ29udHJvbGxlcnMpO1xuICB9XG5cbiAgcHVibGljIGZvcmNlVmFsaWRhdGlvbigpOiB2b2lkIHtcbiAgICB0aGlzLm1pc3NpbmdDb250cm9sbGVycy5jbGVhcigpO1xuICAgIHRoaXMuZWxlbWVudElzc3Vlcy5jbGVhcigpO1xuICAgIHRoaXMuaGFzUmVwb3J0ZWQgPSBmYWxzZTtcbiAgICB0aGlzLnZhbGlkYXRlQ29udHJvbGxlcnMoKTtcbiAgfVxufVxuXG4vLyBOb3RlOiBHbG9iYWwgdHlwZXMgYXJlIGRlY2xhcmVkIGluIHR5cGVzL2dsb2JhbC5kLnRzXG5cbi8vIEluaXRpYWxpemUgdmFsaWRhdG9yXG5pZiAodHlwZW9mIHdpbmRvdyAhPT0gJ3VuZGVmaW5lZCcpIHtcbiAgd2luZG93LnN0aW11bHVzVmFsaWRhdG9yID0gbmV3IFN0aW11bHVzVmFsaWRhdG9yKCk7XG59XG5cbmV4cG9ydCBkZWZhdWx0IFN0aW11bHVzVmFsaWRhdG9yO1xuIl0sCiAgIm1hcHBpbmdzIjogIjtBQUdBLElBQU0sb0JBQU4sTUFBd0I7QUFBQSxFQU90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
