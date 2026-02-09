import { Router } from "express";
import { reportError } from "@/errors/handlers/reportError";


const errorsRouterV3 = Router();
errorsRouterV3.post("/", reportError);
export default errorsRouterV3;