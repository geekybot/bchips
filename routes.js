import Index from "views/Index.js";
import Profile from "views/examples/Profile.js";
import Maps from "views/examples/Maps.js";
import Tables from "views/examples/Tables.js";
import Icons from "views/examples/Icons.js";

import Create from "views/Create.js";
import Assets from "views/Assets.js";
import Edit from "views/Edit.js";
import Issue from "views/Issue.js";
import Dashboard from "views/Dashboard.js";
import Blacklist from "views/Blacklist.js";

var routes = [
    {
        path: "/create",
        name: "Create",
        icon: "ni ni-bullet-list-67 text-red",
        component: Create,
        layout: "/admin",
        hide: false
    },
    // {
    //     path: "/assets",
    //     name: "Assets",
    //     icon: "ni ni-bullet-list-67 text-red",
    //     component: Assets,
    //     layout: "/admin",
    //     hide: false
    // },
    {
        path: "/issue",
        name: "Issue",
        icon: "ni ni-bullet-list-67 text-red",
        component: Issue,
        layout: "/admin",
        hide: false
    // }, {
    //     path: "/edit",
    //     name: "Edit",
    //     icon: "ni ni-bullet-list-67 text-red",
    //     component: Edit,
    //     layout: "/admin",
    //     hide: true
    },
    {
        path: "/blacklist",
        name: "Blacklist",
        icon: "ni ni-bullet-list-67 text-red",
        component: Blacklist,
        layout: "/admin",
        hide: true
    },
    {
        path: "/dashboard",
        name: "Dashboard",
        icon: "ni ni-bullet-list-67 text-red",
        component: Dashboard ,
        layout: "/admin",
        hide: false
    }
    
];
export default routes;