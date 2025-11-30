import {
  __commonJS
} from "./chunk-5WRI5ZAA.js";

// node_modules/flatpickr/dist/l10n/es.js
var require_es = __commonJS({
  "node_modules/flatpickr/dist/l10n/es.js"(exports, module) {
    (function(global, factory) {
      typeof exports === "object" && typeof module !== "undefined" ? factory(exports) : typeof define === "function" && define.amd ? define(["exports"], factory) : (global = typeof globalThis !== "undefined" ? globalThis : global || self, factory(global.es = {}));
    })(exports, (function(exports2) {
      "use strict";
      var fp = typeof window !== "undefined" && window.flatpickr !== void 0 ? window.flatpickr : {
        l10ns: {}
      };
      var Spanish = {
        weekdays: {
          shorthand: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
          longhand: [
            "Domingo",
            "Lunes",
            "Martes",
            "Miércoles",
            "Jueves",
            "Viernes",
            "Sábado"
          ]
        },
        months: {
          shorthand: [
            "Ene",
            "Feb",
            "Mar",
            "Abr",
            "May",
            "Jun",
            "Jul",
            "Ago",
            "Sep",
            "Oct",
            "Nov",
            "Dic"
          ],
          longhand: [
            "Enero",
            "Febrero",
            "Marzo",
            "Abril",
            "Mayo",
            "Junio",
            "Julio",
            "Agosto",
            "Septiembre",
            "Octubre",
            "Noviembre",
            "Diciembre"
          ]
        },
        ordinal: function() {
          return "º";
        },
        firstDayOfWeek: 1,
        rangeSeparator: " a ",
        time_24hr: true
      };
      fp.l10ns.es = Spanish;
      var es = fp.l10ns;
      exports2.Spanish = Spanish;
      exports2.default = es;
      Object.defineProperty(exports2, "__esModule", { value: true });
    }));
  }
});
export default require_es();
//# sourceMappingURL=flatpickr_dist_l10n_es.js.map
